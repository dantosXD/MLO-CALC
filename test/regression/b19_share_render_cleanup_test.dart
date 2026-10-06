import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/share/domain/services/share_template_renderer.dart';

void main() {
  test('empty trailing tokens do not leave dangling " |"', () {
    final out = ShareTemplateRenderer.render(
      '{{mlo_name}} | {{mlo_nmls}} | {{mlo_phone}}\n\nDisclaimer',
      {'mlo_name': 'Jane', 'mlo_nmls': 'NMLS# 1', 'mlo_phone': ''},
    );
    expect(out, 'Jane | NMLS# 1\n\nDisclaimer');
  });

  test('empty middle token collapses separators', () {
    final out = ShareTemplateRenderer.render('{{a}} | {{b}} | {{c}}', {
      'a': 'x',
      'b': '',
      'c': 'z',
    });
    expect(out, 'x | z');
  });

  test('real pipes inside values are kept', () {
    expect(
      ShareTemplateRenderer.render('{{a}} | {{b}}', {'a': 'x', 'b': 'y'}),
      'x | y',
    );
  });
}
