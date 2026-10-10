import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/features/quran/services/qcf_font_service.dart';
import 'package:awqat_salaah/features/quran/services/qcf_layout_service.dart';

void main() {
  testWidgets('loading a page prefetches only its neighbours, without chaining',
      (tester) async {
    final service = QcfLayoutService.instance;
    const radius = QcfFontService.prefetchRadius;

    await tester.runAsync(() async {
      final page = await service.loadPage(300);
      expect(page, isNotNull);
      expect(page!.page, 300);

      // Let the background neighbour loads finish, plus any they might start.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });

    for (var p = 300 - radius; p <= 300 + radius; p++) {
      expect(service.getCachedPage(p), isNotNull, reason: 'page $p');
    }
    expect(service.getCachedPage(300 - radius - 1), isNull);
    expect(service.getCachedPage(300 + radius + 1), isNull);
  });
}
