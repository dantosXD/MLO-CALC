class ShareTemplateRenderer {
  static String render(
    String template,
    Map<String, String> tokens,
  ) {
    var out = template;
    for (final entry in tokens.entries) {
      out = out.replaceAll('{{${entry.key}}}', entry.value);
    }

    out = out.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');
    out = out.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return out.trim();
  }
}
