import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/share_template.dart';

enum ShareChannel {
  sms,
  email,
  shareSheet,
  copy,
  screenshot,
}

class ShareTemplatesProvider with ChangeNotifier {
  ShareTemplatesProvider() {
    _load();
  }

  static const String _customTemplatesKey = 'shareCustomTemplates';
  static const String _selectedTemplateKeyPrefix = 'shareSelectedTemplate_';

  final List<ShareTemplate> _customTemplates = <ShareTemplate>[];
  final Map<ShareChannel, String> _selectedTemplateIds =
      <ShareChannel, String>{};

  List<ShareTemplate> get defaultTemplates => _defaultTemplates;

  List<ShareTemplate> get customTemplates =>
      List<ShareTemplate>.unmodifiable(_customTemplates);

  List<ShareTemplate> get allTemplates {
    return List<ShareTemplate>.unmodifiable(
      <ShareTemplate>[..._defaultTemplates, ..._customTemplates],
    );
  }

  ShareTemplate templateForChannel(ShareChannel channel) {
    final selectedId = _selectedTemplateIds[channel];
    if (selectedId != null) {
      final t = allTemplates.where((t) => t.id == selectedId).toList();
      if (t.isNotEmpty) return t.first;
    }

    switch (channel) {
      case ShareChannel.sms:
        return allTemplates.firstWhere((t) => t.id == 'default_sms_short');
      case ShareChannel.email:
        return allTemplates.firstWhere((t) => t.id == 'default_email_full');
      case ShareChannel.shareSheet:
        return allTemplates.firstWhere((t) => t.id == 'default_share_full');
      case ShareChannel.copy:
        return allTemplates.firstWhere((t) => t.id == 'default_share_full');
      case ShareChannel.screenshot:
        return allTemplates.firstWhere((t) => t.id == 'default_share_full');
    }
  }

  Future<void> setTemplateForChannel(
    ShareChannel channel,
    ShareTemplate template,
  ) async {
    _selectedTemplateIds[channel] = template.id;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_selectedTemplateKeyPrefix${channel.name}',
      template.id,
    );
  }

  Future<void> upsertCustomTemplate({
    required String name,
    String? subject,
    required String body,
  }) async {
    final id = _makeCustomId(name);
    final idx = _customTemplates.indexWhere((t) => t.id == id);
    final template = ShareTemplate(
      id: id,
      name: name,
      subject: subject,
      body: body,
      isDefault: false,
    );

    if (idx >= 0) {
      _customTemplates[idx] = template;
    } else {
      _customTemplates.add(template);
    }

    await _persistCustomTemplates();
    notifyListeners();
  }

  Future<void> deleteCustomTemplate(String id) async {
    _customTemplates.removeWhere((t) => t.id == id);

    for (final entry in _selectedTemplateIds.entries.toList()) {
      if (entry.value == id) {
        _selectedTemplateIds.remove(entry.key);
      }
    }

    await _persistCustomTemplates();

    final prefs = await SharedPreferences.getInstance();
    for (final channel in ShareChannel.values) {
      final key = '$_selectedTemplateKeyPrefix${channel.name}';
      if (prefs.getString(key) == id) {
        await prefs.remove(key);
      }
    }

    notifyListeners();
  }

  String _makeCustomId(String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'custom_$slug';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(_customTemplatesKey);
      if (raw != null && raw.isNotEmpty) {
        _customTemplates
          ..clear()
          ..addAll(ShareTemplate.decodeList(raw));
      }

      for (final channel in ShareChannel.values) {
        final selected =
            prefs.getString('$_selectedTemplateKeyPrefix${channel.name}');
        if (selected != null && selected.isNotEmpty) {
          _selectedTemplateIds[channel] = selected;
        }
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistCustomTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    if (_customTemplates.isEmpty) {
      await prefs.remove(_customTemplatesKey);
      return;
    }

    await prefs.setString(
      _customTemplatesKey,
      ShareTemplate.encodeList(_customTemplates),
    );
  }
}

const List<ShareTemplate> _defaultTemplates = <ShareTemplate>[
  ShareTemplate(
    id: 'default_sms_short',
    name: 'SMS - Short Quote',
    subject: null,
    body:
        'Estimate: {{loan_amount}} at {{interest_rate}} for {{term_years}}. P&I {{pi_payment}} | PITI {{piti_payment}}. {{disclaimer}}',
    isDefault: true,
  ),
  ShareTemplate(
    id: 'default_sms_breakdown',
    name: 'SMS - With Breakdown',
    subject: null,
    body:
        'Estimate: {{loan_amount}} @ {{interest_rate}} ({{term_years}})\nP&I: {{pi_payment}}\nTax: {{monthly_tax}} Ins: {{monthly_insurance}} MI: {{monthly_mi}} HOA: {{monthly_hoa}}\nPITI: {{piti_payment}}\n{{disclaimer}}',
    isDefault: true,
  ),
  ShareTemplate(
    id: 'default_email_full',
    name: 'Email - Detailed Quote',
    subject: 'Mortgage estimate - {{scenario_name}}',
    body:
        'Hi {{borrower_name}},\n\nHere is an estimated mortgage quote based on the details below:\n\nScenario: {{scenario_name}}\nLoan: {{loan_amount}}\nRate: {{interest_rate}}\nTerm: {{term_years}}\n\nP&I: {{pi_payment}}\nEstimated PITI: {{piti_payment}}\n\nEstimated cash to close: {{cash_to_close}}\n\n{{disclaimer}}',
    isDefault: true,
  ),
  ShareTemplate(
    id: 'default_share_full',
    name: 'Share/Copy - Standard Quote',
    subject: 'Mortgage estimate',
    body:
        'Scenario: {{scenario_name}}\nLoan: {{loan_amount}} | Rate: {{interest_rate}} | Term: {{term_years}}\nP&I: {{pi_payment}} | Est PITI: {{piti_payment}}\nCash to close (est): {{cash_to_close}}\n\n{{disclaimer}}',
    isDefault: true,
  ),
];
