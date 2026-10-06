class ShareTemplateRenderer {
  /// The canonical placeholder form for [key], e.g. `{{name}}`. Single source
  /// of truth so UI hints (tap-to-copy chips) can never drift from what
  /// [render] actually substitutes.
  static String placeholder(String key) => '{{$key}}';

  static String render(String template, Map<String, String> tokens) {
    var out = template;
    for (final entry in tokens.entries) {
      out = out.replaceAll(placeholder(entry.key), entry.value);
    }

    out = out.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');
    // Empty tokens leave dangling separators ("a | b |", "| |"); tidy per line.
    out = out.replaceAll(RegExp(r'(?:[ \t]*\|[ \t]*){2,}'), ' | ');
    out = out.replaceAll(RegExp(r'^[ \t]*\|[ \t]*', multiLine: true), '');
    out = out.replaceAll(RegExp(r'[ \t]*\|[ \t]*$', multiLine: true), '');
    out = out.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return out.trim();
  }
}
