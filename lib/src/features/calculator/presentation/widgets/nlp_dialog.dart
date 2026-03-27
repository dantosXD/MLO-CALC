import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loan_ranger/src/core/utils/constants.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/voice_waveform.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NlpDialog extends StatefulWidget {
  const NlpDialog({
    super.key,
    required this.nlpService,
    required this.speechToText,
    this.onStateChanged,
  });

  final NLPCalculatorService nlpService;
  final stt.SpeechToText speechToText;
  final void Function(bool isListening, bool isProcessing, bool hasError)?
      onStateChanged;

  @override
  State<NlpDialog> createState() => _NlpDialogState();
}

class _NlpDialogState extends State<NlpDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isListening = false;
  bool _isProcessing = false;
  String? _status;
  double _soundLevel = 0.0;
  Timer? _autoSubmitTimer;

  @override
  void dispose() {
    _autoSubmitTimer?.cancel();
    unawaited(widget.speechToText.stop());
    _controller.dispose();
    super.dispose();
  }

  void _notifyStateChange() {
    widget.onStateChanged?.call(_isListening, _isProcessing, _status != null && _status!.startsWith('Error'));
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    
    if (_isListening) {
      await widget.speechToText.stop();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      _notifyStateChange();
      return;
    }

    final available = await widget.speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _status = status);
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
          });
        }
        _notifyStateChange();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _status = 'Error: ${error.errorMsg}');
        _notifyStateChange();
      },
    );

    if (!available) {
      setState(() {
        _status = 'Error: Microphone not available';
      });
      _notifyStateChange();
      return;
    }

    setState(() => _isListening = true);
    _notifyStateChange();

    await widget.speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });

        if (result.finalResult) {
          _autoSubmitTimer?.cancel();
          if (result.recognizedWords.isNotEmpty) {
            // Auto-submit after a short pause to let user review
            _autoSubmitTimer = Timer(const Duration(milliseconds: 1500), () {
              if (mounted && !_isProcessing && !_isListening) {
                HapticFeedback.lightImpact();
                _runNlp();
              }
            });
          }
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

  Future<void> _runNlp() async {
    _autoSubmitTimer?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _status = 'Please say or type a question.');
      HapticFeedback.selectionClick();
      _notifyStateChange();
      return;
    }

    final settings = context.read<NlpSettingsProvider>();
    final apiKey = settings.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _status = 'Error: Add your Gemini API key in Settings.');
      _notifyStateChange();
      return;
    }

    final calculator = context.read<CalculatorProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isProcessing = true;
      _status = 'Understanding your request...';
    });
    _notifyStateChange();

    try {
      // Check cache first
      final cached = settings.cache.getCachedResponse(query);
      if (cached != null) {
        setState(() => _status = 'Using cached response...');
        final String resultMessage = await calculator.applyNlpRequest(cached.response);
        
        HapticFeedback.mediumImpact();
        if (!mounted) return;
        navigator.pop();
        messenger.showSnackBar(SnackBar(
          content: Text('$resultMessage (cached)'),
          action: SnackBarAction(
            label: 'Refresh',
            onPressed: () async {
              // Queue for fresh response
              await settings.cache.queueRequest(query);
            },
          ),
        ));
        return;
      }
      
      // Check if offline
      if (settings.isOffline) {
        // Queue request for later
        await settings.cache.queueRequest(query);
        setState(() => _status = 'Offline - request queued for later');
        HapticFeedback.selectionClick();
        
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        navigator.pop();
        messenger.showSnackBar(const SnackBar(
          content: Text('You\'re offline. Request saved for when you reconnect.'),
        ));
        return;
      }
      
      await widget.nlpService.initialize(apiKey);
      final request = await widget.nlpService.processQuery(query);
      
      // Cache the response
      await settings.cache.cacheResponse(query, request);
      
      final String resultMessage = await calculator.applyNlpRequest(request);
      
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(resultMessage)));
    } catch (e) {
      // If error and offline, queue for later
      if (settings.isOffline) {
        await settings.cache.queueRequest(query);
        setState(() => _status = 'Offline - request queued');
      } else {
        setState(() => _status = 'Error: $e');
      }
      HapticFeedback.heavyImpact();
      _notifyStateChange();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _notifyStateChange();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.nlpService.getSuggestions();
    final settings = context.watch<NlpSettingsProvider>();

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Voice Assistant')),
          if (settings.isOffline)
            Tooltip(
              message: 'Offline - cached responses available',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
          if (settings.hasPendingRequests)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Badge(
                label: Text('${settings.pendingRequestCount}'),
                child: const Icon(Icons.schedule, size: 18),
              ),
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Visualizer
          SizedBox(
            height: 60,
            child: Center(
              child: VoiceWaveform(
                isListening: _isListening,
                level: _soundLevel,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Input Field
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Tap the mic and speak...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.keyboard),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 3,
            onSubmitted: (_) => _runNlp(),
          ),
          
          const SizedBox(height: 12),
          
          // Suggestions
          if (_controller.text.isEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.take(2).map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    _controller.text = s;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: s.length),
                    );
                  },
                );
              }).toList(),
            ),
            
          const SizedBox(height: 8),
          if (_status != null)
            Text(
              _status!,
              style: TextStyle(
                fontSize: 12, 
                color: (_status!.startsWith('Error')) ? Colors.red : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        // Cancel Button
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        
        const SizedBox(width: 8),

        // Microphone Button (FAB-like)
        SizedBox(
          width: 64,
          height: 64,
          child: FloatingActionButton(
            elevation: _isListening ? 8 : 2,
            backgroundColor: _isListening 
                ? AppConstants.micListeningColor 
                : (_isProcessing ? AppConstants.micProcessingColor : AppConstants.micIdleColor),
            onPressed: _isProcessing ? null : _toggleListening,
            child: Icon(
              _isListening ? Icons.stop : Icons.mic,
              size: 32,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send Button
        IconButton(
          icon: _isProcessing 
              ? const SizedBox(
                  width: 24, height: 24, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : const Icon(Icons.send),
          onPressed: _isProcessing ? null : _runNlp,
          color: Theme.of(context).colorScheme.primary,
          tooltip: 'Process',
        ),
      ],
    );
  }
}
