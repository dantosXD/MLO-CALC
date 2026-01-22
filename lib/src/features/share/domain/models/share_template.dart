import 'dart:convert';

class ShareTemplate {
  const ShareTemplate({
    required this.id,
    required this.name,
    this.subject,
    required this.body,
    required this.isDefault,
  });

  final String id;
  final String name;
  final String? subject;
  final String body;
  final bool isDefault;

  ShareTemplate copyWith({
    String? id,
    String? name,
    String? subject,
    String? body,
    bool? isDefault,
  }) {
    return ShareTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'body': body,
    };
  }

  static ShareTemplate fromJson(Map<String, dynamic> json) {
    return ShareTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String?,
      body: json['body'] as String,
      isDefault: false,
    );
  }

  static String encodeList(List<ShareTemplate> templates) {
    final list = templates.map((t) => t.toJson()).toList();
    return jsonEncode(list);
  }

  static List<ShareTemplate> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => ShareTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
