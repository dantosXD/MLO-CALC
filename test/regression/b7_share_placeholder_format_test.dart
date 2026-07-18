// Regression: BUGLOG B7 — the share dialog's tap-to-copy hint chips showed
// tokens as triple-brace `{{{key}}}` while the renderer substitutes double-brace
// `{{key}}`. Copying a hint into a custom template produced a broken `{value}`.
// The placeholder form is now single-sourced via ShareTemplateRenderer.placeholder
// so the hint can never drift from what render() actually replaces.
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/share/domain/services/share_template_renderer.dart';

void main() {
  group('B7: share placeholder format is single-sourced and round-trips', () {
    test('placeholder(key) uses double braces', () {
      expect(ShareTemplateRenderer.placeholder('name'), '{{name}}');
    });

    test('a placeholder round-trips through render() to its value', () {
      final token = ShareTemplateRenderer.placeholder('name');
      final out = ShareTemplateRenderer.render(token, {'name': 'Jane Doe'});
      expect(out, 'Jane Doe');
    });

    test('the old triple-brace form does NOT round-trip (documents the bug)', () {
      // Guards against reintroducing `{{{key}}}` in the hint chips: it leaves a
      // stray brace instead of substituting cleanly.
      final out = ShareTemplateRenderer.render('{{{name}}}', {'name': 'Jane'});
      expect(out, isNot('Jane'));
    });
  });
}
