import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loan_ranger/src/core/utils/constants.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/voice_waveform.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Modern bottom sheet for voice and natural language mortgage calculations.
/// Supports both Gemini AI and instant offline/zero-key rule-based calculations.
class NlpBottomSheet extends StatefulWidget {
  const NlpBottomSheet({
    super.key,
    required this.nlpService,
    required this.speechToText,
  });

  final NLPCalculatorService nlpService;
  final stt.SpeechToText speechToText;

  static Future<void> show(BuildContext context) {
    final nlpService = context.read<NlpSettingsProvider>().calculatorService;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NlpBottomSheet(
        nlpService: nlpService,
        speechToText: stt.SpeechToText(),
      ),
    );
  }

  @override
  State<NlpBottomSheet> createState() => _NlpBottomSheetState();
}

class _NlpBottomSheetState extends State<NlpBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isListening = false;
  bool _isProcessing = false;
  String? _status;
  double _soundLevel = 0.0;
  CalculationRequest? _extractedRequest;

  @override
  void initState() {
    super.initState();
    // Auto-start listening on open for immediate hands-free convenience
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningIfAvailable();
    });
  }

  @override
  void dispose() {
    unawaited(widget.speechToText.stop());
    _controller.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (e is SocketException || msg.contains('SocketException')) {
      return 'Network offline. Using local calculation engine.';
    }
    if (e is TimeoutException || msg.contains('TimeoutException')) {
      return 'Request timed out. Local engine ready.';
    }
    if (msg.contains('quota') || msg.contains('429')) {
      return 'API quota reached. Using local calculation engine.';
    }
    return 'Could not process query. Try rewording or adjusting numbers.';
  }

  Future<void> _startListeningIfAvailable() async {
    try {
      final available = await widget.speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
              _soundLevel = 0.0;
            });
            // If we have words and haven't processed yet, analyze them
            if (_controller.text.trim().isNotEmpty && _extractedRequest == null && !_isProcessing) {
              _processQuery();
            }
          }
        },
        onError: (error) {
          if (!mounted) return;
          if (kDebugMode) {
            debugPrint('Speech recognition notice: ${error.errorMsg}');
          }
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
          });
        },
      );

      if (available && mounted) {
        await _listen();
      }
    } catch (_) {
      // Audio or permission unavailable; user can type
    }
  }

  Future<void> _listen() async {
    setState(() {
      _isListening = true;
      _status = 'Listening... Speak naturally.';
    });
    unawaited(HapticFeedback.lightImpact());

    await widget.speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.collapsed(
            offset: result.recognizedWords.length,
          );
        });

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _processQuery();
        }
      },
      onSoundLevelChange: (level) {
        if (mounted) {
          setState(() => _soundLevel = level);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> _toggleListening() async {
    unawaited(HapticFeedback.mediumImpact());
    if (_isListening) {
      await widget.speechToText.stop();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      if (_controller.text.trim().isNotEmpty) {
        await _processQuery();
      }
    } else {
      await _listen();
    }
  }

  Future<void> _processQuery([String? explicitQuery]) async {
    final query = (explicitQuery ?? _controller.text).trim();
    if (query.isEmpty) {
      setState(() => _status = 'Please speak or type a calculation request.');
      return;
    }

    if (_isListening) {
      await widget.speechToText.stop();
      if (!mounted) return;
      _isListening = false;
    }

    final settings = context.read<NlpSettingsProvider>();
    final apiKey = settings.apiKey;

    setState(() {
      _isProcessing = true;
      _status = (apiKey != null && apiKey.isNotEmpty)
          ? 'Understanding with Gemini AI...'
          : 'Parsing loan parameters...';
    });

    try {
      if (apiKey != null && apiKey.isNotEmpty) {
        await widget.nlpService.initialize(apiKey);
      }

      final request = await widget.nlpService.processQuery(
        query,
        previousContext: _extractedRequest,
      );
      if (!mounted) return;

      setState(() {
        _extractedRequest = request;
        _status = null;
      });
      unawaited(HapticFeedback.selectionClick());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _friendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _applyToCalculator() async {
    final req = _extractedRequest;
    if (req == null) return;

    final calculator = context.read<CalculatorProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    unawaited(HapticFeedback.mediumImpact());
    final message = await calculator.applyNlpRequest(req);

    if (!mounted) return;
    nav.pop();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<NlpSettingsProvider>();
    final hasGeminiKey = settings.hasKey;
    final suggestions = widget.nlpService.getSuggestions();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Text(
                'Voice & Smart Assistant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasGeminiKey
                      ? Colors.purple.withValues(alpha: 0.12)
                      : Colors.blueGrey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasGeminiKey ? Icons.auto_awesome : Icons.bolt,
                      size: 13,
                      color: hasGeminiKey ? Colors.purple : Colors.blueGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasGeminiKey ? 'Gemini AI' : 'Instant Mode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasGeminiKey ? Colors.purple : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speech Waveform and Listening Visualizer
          Center(
            child: GestureDetector(
              onTap: _isProcessing ? null : _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppConstants.micListeningColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    elevation: _isListening ? 6 : 2,
                    backgroundColor: _isListening
                        ? AppConstants.micListeningColor
                        : (_isProcessing
                            ? AppConstants.micProcessingColor
                            : Theme.of(context).colorScheme.primary),
                    foregroundColor: Colors.white,
                    onPressed: _isProcessing ? null : _toggleListening,
                    tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_isListening ? Icons.stop : Icons.mic, size: 28),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Live audio waveform
          SizedBox(
            height: 36,
            child: Center(
              child: VoiceWaveform(
                isListening: _isListening,
                level: _soundLevel,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Text Field for query
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Speak or type: "400k at 6.5% for 30 years"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              prefixIcon: Icon(
                _isListening ? Icons.mic : Icons.chat_bubble_outline,
                color: _isListening
                    ? AppConstants.micListeningColor
                    : Colors.grey,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _isProcessing ? null : () => _processQuery(),
                      tooltip: 'Analyze query',
                    )
                  : null,
            ),
            maxLines: 2,
            minLines: 1,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty && !_isProcessing) {
                _processQuery(val);
              }
            },
          ),
          const SizedBox(height: 8),

          // Status message if any
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _status!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _status!.contains('Error') || _status!.contains('offline')
                      ? Colors.orange.shade800
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // Extracted Parameters Preview Card
          if (_extractedRequest != null) ...[
            _ExtractedPreviewCard(
              request: _extractedRequest!,
              onApply: _applyToCalculator,
              onClear: () {
                setState(() {
                  _extractedRequest = null;
                });
              },
            ),
            const SizedBox(height: 12),
          ],

          // Suggestions (if no text or no extracted request)
          if (_controller.text.isEmpty && _extractedRequest == null) ...[
            Text(
              'Try asking:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions.take(3).map((s) {
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    _controller.text = s;
                    _processQuery(s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Conversational follow-up chips when an active scenario exists
          if (_extractedRequest != null) ...[
            Text(
              'Refine this scenario:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'Change term to 15 years',
                'What if rate was 6.0%?',
                'Add 20% down payment',
              ].map((s) {
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.edit_outlined, size: 12),
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    _controller.text = s;
                    _processQuery(s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Footer Gemini key notice
          if (!hasGeminiKey)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Instant offline engine active. Add Gemini API key for advanced conversational queries.',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExtractedPreviewCard extends StatelessWidget {
  const _ExtractedPreviewCard({
    required this.request,
    required this.onApply,
    required this.onClear,
  });

  final CalculationRequest request;
  final VoidCallback onApply;
  final VoidCallback onClear;

  String _formatAction(String action) {
    switch (action) {
      case 'calculate_payment':
        return 'Payment Calculation';
      case 'calculate_loan_amount':
        return 'Loan Amount Calculation';
      case 'calculate_term':
        return 'Loan Term Calculation';
      case 'calculate_interest_rate':
        return 'Interest Rate Calculation';
      case 'calculate_max_qualifying_loan':
        return 'Max Qualifying Loan';
      case 'calculate_min_income':
        return 'Minimum Income Requirement';
      case 'generate_amortization':
        return 'Amortization Schedule';
      case 'calculate_biweekly':
        return 'Bi-Weekly Payment';
      default:
        return 'Mortgage Scenario';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    void addChip(String label, String value) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    if (request.loanAmount != null) {
      addChip('Loan', CurrencyFormatter.formatCurrency(request.loanAmount));
    }
    if (request.price != null) {
      addChip('Price', CurrencyFormatter.formatCurrency(request.price));
    }
    if (request.downPayment != null) {
      addChip('Down', CurrencyFormatter.formatCurrency(request.downPayment));
    }
    if (request.interestRate != null) {
      addChip('Rate', CurrencyFormatter.formatPercent(request.interestRate));
    }
    if (request.termYears != null) {
      addChip('Term', '${request.termYears!.toStringAsFixed(0)} yrs');
    }
    if (request.payment != null) {
      addChip('Payment', CurrencyFormatter.formatCurrency(request.payment));
    }
    if (request.annualIncome != null) {
      addChip('Income', CurrencyFormatter.formatCurrency(request.annualIncome));
    }
    if (request.monthlyDebt != null) {
      addChip('Debt', CurrencyFormatter.formatCurrency(request.monthlyDebt));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                _formatAction(request.action),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClear,
                tooltip: 'Dismiss',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.explanation,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Apply to Calculator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
