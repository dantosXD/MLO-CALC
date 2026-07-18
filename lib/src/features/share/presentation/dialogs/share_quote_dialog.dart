import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:loan_ranger/src/features/settings/domain/providers/mlo_profile_provider.dart';
import 'package:loan_ranger/src/features/share/application/providers/share_templates_provider.dart';
import 'package:loan_ranger/src/features/share/domain/models/quote_share_data.dart';
import 'package:loan_ranger/src/features/share/domain/models/share_template.dart';
import 'package:loan_ranger/src/features/share/domain/services/share_template_renderer.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareQuoteDialog extends StatefulWidget {
  const ShareQuoteDialog({
    super.key,
    required this.data,
    this.borrowerName,
    this.scenarioName,
    this.title,
  });

  final QuoteShareData data;
  final String? borrowerName;
  final String? scenarioName;
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required QuoteShareData data,
    String? borrowerName,
    String? scenarioName,
    String? title,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ShareQuoteDialog(
        data: data,
        borrowerName: borrowerName,
        scenarioName: scenarioName,
        title: title,
      ),
    );
  }

  @override
  State<ShareQuoteDialog> createState() => _ShareQuoteDialogState();
}

class _ShareQuoteDialogState extends State<ShareQuoteDialog> {
  late ShareChannel _channel;

  ShareTemplate? _selectedTemplate;
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  late final TextEditingController _borrowerController;
  late final TextEditingController _scenarioController;

  String? _lastRenderedBody;
  String? _lastRenderedSubject;

  bool _busy = false;
  String? _error;

  final GlobalKey _screenshotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _channel = ShareChannel.shareSheet;

    _borrowerController = TextEditingController(
      text: widget.borrowerName ?? '',
    );
    _scenarioController = TextEditingController(
      text: widget.scenarioName ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ShareTemplatesProvider>();
      final template = provider.templateForChannel(_channel);
      _applyTemplate(template);
    });
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _subjectController.dispose();
    _borrowerController.dispose();
    _scenarioController.dispose();
    super.dispose();
  }

  Map<String, String> get _tokens => widget.data.toTokenMap(
    borrowerName: _borrowerController.text.trim(),
    scenarioName: _scenarioController.text.trim(),
    mloTokens: context.read<MloProfileProvider>().toTokenMap(),
  );

  void _applyTemplate(ShareTemplate template) {
    final renderedBody = ShareTemplateRenderer.render(template.body, _tokens);
    final renderedSubject = template.subject != null
        ? ShareTemplateRenderer.render(template.subject!, _tokens)
        : '';

    setState(() {
      _selectedTemplate = template;
      _bodyController.text = renderedBody;
      _subjectController.text = renderedSubject;
      _lastRenderedBody = renderedBody;
      _lastRenderedSubject = renderedSubject;
      _error = null;
    });
  }

  void _reapplyIfSafe() {
    final template = _selectedTemplate;
    if (template == null) return;

    final renderedBody = ShareTemplateRenderer.render(template.body, _tokens);
    final renderedSubject = template.subject != null
        ? ShareTemplateRenderer.render(template.subject!, _tokens)
        : '';

    final shouldOverwriteBody =
        _lastRenderedBody == null || _bodyController.text == _lastRenderedBody;
    final shouldOverwriteSubject =
        _lastRenderedSubject == null ||
        _subjectController.text == _lastRenderedSubject;

    setState(() {
      if (shouldOverwriteBody) {
        _bodyController.text = renderedBody;
        _lastRenderedBody = renderedBody;
      }
      if (shouldOverwriteSubject) {
        _subjectController.text = renderedSubject;
        _lastRenderedSubject = renderedSubject;
      }
    });
  }

  Future<void> _editTemplateSource() async {
    final current = _selectedTemplate;
    if (current == null) return;

    final provider = context.read<ShareTemplatesProvider>();

    final nameController = TextEditingController(text: current.name);
    final subjectController = TextEditingController(
      text: current.subject ?? '',
    );
    final bodyController = TextEditingController(text: current.body);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactDialog = screenWidth < 600;

    final result = await showDialog<_TemplateEditResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit template'),
          contentPadding: isCompactDialog
              ? const EdgeInsets.fromLTRB(16, 12, 16, 0)
              : const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: isCompactDialog ? double.maxFinite : 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject (optional, supports placeholders)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: isCompactDialog ? 6 : 10,
                    decoration: const InputDecoration(
                      labelText: 'Template body (supports placeholders)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PlaceholdersHelp(
                    tokens: _tokens,
                    isCompact: isCompactDialog,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.of(context).pop(
                  _TemplateEditResult(
                    name: name,
                    subject: subjectController.text.trim().isEmpty
                        ? null
                        : subjectController.text.trim(),
                    body: bodyController.text,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await provider.upsertCustomTemplate(
      name: result.name,
      subject: result.subject,
      body: result.body,
    );

    final updated = provider.allTemplates
        .where((t) => t.id == 'custom_${_slug(result.name)}')
        .toList();
    if (updated.isNotEmpty) {
      await provider.setTemplateForChannel(_channel, updated.first);
      _applyTemplate(updated.first);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Template saved')));
  }

  Future<void> _setChannel(ShareChannel channel) async {
    final provider = context.read<ShareTemplatesProvider>();
    final template = provider.templateForChannel(channel);
    setState(() => _channel = channel);
    _applyTemplate(template);
  }

  Future<void> _saveAsTemplate() async {
    final provider = context.read<ShareTemplatesProvider>();

    final nameController = TextEditingController();
    final subjectController = TextEditingController(
      text: _subjectController.text,
    );

    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Template name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Email subject (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = nameController.text.trim();
              if (v.isEmpty) return;
              Navigator.of(context).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null) return;

    await provider.upsertCustomTemplate(
      name: name,
      subject: subjectController.text.trim().isEmpty
          ? null
          : subjectController.text.trim(),
      body: _bodyController.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved template "$name"')));

    final created = provider.allTemplates
        .where((t) => t.id == 'custom_${_slug(name)}')
        .toList();
    if (created.isNotEmpty) {
      await provider.setTemplateForChannel(_channel, created.first);
      _applyTemplate(created.first);
    }
  }

  String _slug(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final body = _bodyController.text.trim();
      final subject = _subjectController.text.trim();

      final box = context.findRenderObject() as RenderBox?;
      final Rect? shareOrigin = box != null
          ? (box.localToGlobal(Offset.zero) & box.size)
          : null;

      switch (_channel) {
        case ShareChannel.copy:
          await Clipboard.setData(ClipboardData(text: body));
          break;

        case ShareChannel.shareSheet:
          await SharePlus.instance.share(
            ShareParams(
              text: body.isEmpty ? null : body,
              subject: subject.isEmpty ? null : subject,
              sharePositionOrigin: shareOrigin,
            ),
          );
          break;

        case ShareChannel.sms:
          final uri = Uri(
            scheme: 'sms',
            queryParameters: <String, String>{'body': body},
          );
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw Exception('Unable to open SMS app');
          }
          break;

        case ShareChannel.email:
          final uri = Uri(
            scheme: 'mailto',
            queryParameters: <String, String>{
              if (subject.isNotEmpty) 'subject': subject,
              'body': body,
            },
          );
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw Exception('Unable to open email app');
          }
          break;

        case ShareChannel.screenshot:
          final bytes = await _captureScreenshotPng();
          final file = XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'mlo_quote.png',
          );

          await SharePlus.instance.share(
            ShareParams(
              files: [file],
              text: body.isEmpty ? null : body,
              subject: subject.isEmpty ? null : subject,
              sharePositionOrigin: shareOrigin,
            ),
          );
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _channel == ShareChannel.copy
                ? 'Copied to clipboard'
                : 'Ready to send',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<Uint8List> _captureScreenshotPng() async {
    final boundary =
        _screenshotKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('Screenshot not ready');
    }

    final ui.Image image = await boundary.toImage(
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Unable to encode image');
    }
    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final templatesProvider = context.watch<ShareTemplatesProvider>();
    final templates = templatesProvider.allTemplates;

    final title = widget.title ?? 'Share Quote';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return AlertDialog(
      title: Text(title),
      contentPadding: isCompact
          ? const EdgeInsets.fromLTRB(16, 12, 16, 0)
          : const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: isCompact ? double.maxFinite : 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isCompact)
              Column(
                children: [
                  TextField(
                    controller: _borrowerController,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Borrower (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _reapplyIfSafe(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _scenarioController,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Scenario (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _reapplyIfSafe(),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _borrowerController,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Borrower (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _reapplyIfSafe(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _scenarioController,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Scenario (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _reapplyIfSafe(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            _ChannelPicker(
              value: _channel,
              onChanged: _busy ? null : (c) => _setChannel(c),
              isCompact: isCompact,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedTemplate?.id,
              decoration: const InputDecoration(
                labelText: 'Template',
                border: OutlineInputBorder(),
              ),
              items: templates
                  .map(
                    (t) => DropdownMenuItem<String>(
                      value: t.id,
                      child: Text(
                        t.isDefault ? '${t.name} (default)' : t.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (id) async {
                      if (id == null) return;
                      final t = templates.firstWhere((t) => t.id == id);
                      await templatesProvider.setTemplateForChannel(
                        _channel,
                        t,
                      );
                      _applyTemplate(t);
                    },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : _editTemplateSource,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit template'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _reapplyIfSafe,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reapply template'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (_channel == ShareChannel.email ||
                _channel == ShareChannel.shareSheet ||
                _channel == ShareChannel.screenshot)
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject (optional)',
                  border: OutlineInputBorder(),
                ),
                enabled: !_busy,
              ),
            if (_channel == ShareChannel.email ||
                _channel == ShareChannel.shareSheet ||
                _channel == ShareChannel.screenshot)
              const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              enabled: !_busy,
              maxLines: isCompact ? 5 : 8,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _PlaceholdersHelp(tokens: _tokens, isCompact: isCompact),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_channel == ShareChannel.screenshot) ...[
              const SizedBox(height: 12),
              Text(
                'Screenshot preview',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                key: _screenshotKey,
                child: _QuoteCardPreview(
                  data: widget.data,
                  scenarioName: _scenarioController.text,
                  mloTokens: context.read<MloProfileProvider>().toTokenMap(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _saveAsTemplate,
          child: const Text('Save as template'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _send,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_buttonLabel(_channel)),
        ),
      ],
    );
  }

  String _buttonLabel(ShareChannel channel) => switch (channel) {
    ShareChannel.sms => 'Text',
    ShareChannel.email => 'Email',
    ShareChannel.shareSheet => 'Share',
    ShareChannel.copy => 'Copy',
    ShareChannel.screenshot => 'Share Image',
  };
}

class _ChannelPicker extends StatelessWidget {
  const _ChannelPicker({
    required this.value,
    required this.onChanged,
    this.isCompact = false,
  });

  final ShareChannel value;
  final ValueChanged<ShareChannel>? onChanged;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // On compact screens, use a dropdown instead of segmented button
    if (isCompact) {
      return DropdownButtonFormField<ShareChannel>(
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Share via',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(
            value: ShareChannel.shareSheet,
            child: Row(
              children: [
                Icon(Icons.ios_share, size: 20),
                SizedBox(width: 8),
                Text('Share'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ShareChannel.copy,
            child: Row(
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 8),
                Text('Copy to Clipboard'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ShareChannel.sms,
            child: Row(
              children: [
                Icon(Icons.sms_outlined, size: 20),
                SizedBox(width: 8),
                Text('Text Message'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ShareChannel.email,
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 20),
                SizedBox(width: 8),
                Text('Email'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ShareChannel.screenshot,
            child: Row(
              children: [
                Icon(Icons.image_outlined, size: 20),
                SizedBox(width: 8),
                Text('Share as Image'),
              ],
            ),
          ),
        ],
        onChanged: onChanged == null
            ? null
            : (v) {
                if (v != null) onChanged?.call(v);
              },
      );
    }

    return SegmentedButton<ShareChannel>(
      segments: const <ButtonSegment<ShareChannel>>[
        ButtonSegment(
          value: ShareChannel.shareSheet,
          icon: Icon(Icons.ios_share),
          label: Text('Share'),
        ),
        ButtonSegment(
          value: ShareChannel.copy,
          icon: Icon(Icons.copy),
          label: Text('Copy'),
        ),
        ButtonSegment(
          value: ShareChannel.sms,
          icon: Icon(Icons.sms_outlined),
          label: Text('Text'),
        ),
        ButtonSegment(
          value: ShareChannel.email,
          icon: Icon(Icons.email_outlined),
          label: Text('Email'),
        ),
        ButtonSegment(
          value: ShareChannel.screenshot,
          icon: Icon(Icons.image_outlined),
          label: Text('Image'),
        ),
      ],
      selected: <ShareChannel>{value},
      onSelectionChanged: onChanged == null
          ? null
          : (set) {
              if (set.isEmpty) return;
              onChanged?.call(set.first);
            },
    );
  }
}

class _TemplateEditResult {
  const _TemplateEditResult({
    required this.name,
    required this.subject,
    required this.body,
  });

  final String name;
  final String? subject;
  final String body;
}

class _PlaceholdersHelp extends StatelessWidget {
  const _PlaceholdersHelp({required this.tokens, this.isCompact = false});

  final Map<String, String> tokens;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keys = tokens.keys.toList()..sort();

    // On compact screens, show an expandable section
    if (isCompact) {
      return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          'Placeholders (tap to copy)',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: keys.map((k) {
              final label = ShareTemplateRenderer.placeholder(k);

              return InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: label));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Copied $label')));
                },
                child: Chip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Placeholders you can use (tap to copy):',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: keys.map((k) {
                final v = tokens[k] ?? '';
                final label = ShareTemplateRenderer.placeholder(k);
                final text = v.isEmpty ? label : '$label → $v';

                return InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: label));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Copied $label')));
                  },
                  child: Chip(
                    label: Text(text),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteCardPreview extends StatelessWidget {
  const _QuoteCardPreview({
    required this.data,
    required this.scenarioName,
    required this.mloTokens,
  });

  final QuoteShareData data;
  final String? scenarioName;
  final Map<String, String> mloTokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String line(String label, String value) {
      return '$label: $value';
    }

    final tokens = data.toTokenMap(scenarioName: scenarioName, mloTokens: mloTokens);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: scheme.onSurface, fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (scenarioName?.trim().isNotEmpty ?? false)
                  ? scenarioName!.trim()
                  : 'Mortgage Estimate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              line('Loan', tokens['loan_amount'] ?? ''),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(line('Rate', tokens['interest_rate'] ?? '')),
            Text(line('Term', tokens['term_years'] ?? '')),
            const SizedBox(height: 8),
            Text(line('P&I', tokens['pi_payment'] ?? '')),
            Text(line('Est PITI', tokens['piti_payment'] ?? '')),
            Text(line('Cash to close (est)', tokens['cash_to_close'] ?? '')),
            const SizedBox(height: 8),
            Text(
              tokens['disclaimer'] ?? '',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
