import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Singleton service responsible for downloading, caching, and dynamically
/// registering Quran Foundation QCF V2 fonts into Flutter's runtime font manifest.
class QcfFontService {
  static final QcfFontService instance = QcfFontService._internal();

  QcfFontService._internal();

  static const String _cdnBaseUrl =
      'https://verses.quran.foundation/fonts/quran/hafs/v2/ttf';

  /// Pages whose fonts have been successfully registered into Flutter FontLoader.
  final Set<int> _loadedPages = <int>{};

  /// Pages currently being fetched/loaded to prevent duplicate concurrent network requests.
  final Map<int, Future<bool>> _inFlightLoads = <int, Future<bool>>{};

  /// Notifier that emits the page number whenever a font is newly loaded,
  /// allowing Mushaf widgets to trigger a repaint.
  final ValueNotifier<int> fontLoadedNotifier = ValueNotifier<int>(0);

  /// Returns the font family string to use for a given page.
  /// Format: 'QCF_P{page}' (e.g. 'QCF_P1', 'QCF_P604').
  static String fontFamilyForPage(int page) => 'QCF_P$page';

  /// Checks whether the font for [page] has already been loaded into the engine.
  bool isFontLoaded(int page) => _loadedPages.contains(page);

  /// Ensures that the font for [page] is loaded into Flutter.
  /// Also triggers background prefetching for adjacent pages (page - 1, page + 1).
  Future<bool> ensurePageFont(int page) async {
    if (page < 1 || page > 604) return false;

    if (_loadedPages.contains(page)) {
      _prefetchAdjacent(page);
      return true;
    }

    if (_inFlightLoads.containsKey(page)) {
      return _inFlightLoads[page]!;
    }

    final future = _loadFontForPage(page);
    _inFlightLoads[page] = future;

    final success = await future;
    _inFlightLoads.remove(page);

    if (success) {
      _prefetchAdjacent(page);
    }

    return success;
  }

  void _prefetchAdjacent(int page) {
    if (page > 1 && !_loadedPages.contains(page - 1) && !_inFlightLoads.containsKey(page - 1)) {
      ensurePageFont(page - 1);
    }
    if (page < 604 && !_loadedPages.contains(page + 1) && !_inFlightLoads.containsKey(page + 1)) {
      ensurePageFont(page + 1);
    }
  }

  Future<bool> _loadFontForPage(int page) async {
    try {
      Uint8List? fontBytes;

      // 1. Try reading from local disk cache on non-web platforms
      if (!kIsWeb) {
        final cacheFile = await _getCacheFile(page);
        if (await cacheFile.exists()) {
          try {
            final bytes = await cacheFile.readAsBytes();
            if (bytes.length > 1000) {
              fontBytes = bytes;
            }
          } catch (e) {
            debugPrint('[QcfFontService] Error reading cache for p$page: $e');
          }
        }
      }

      // 2. Fetch from CDN if not cached locally
      if (fontBytes == null) {
        final url = Uri.parse('$_cdnBaseUrl/p$page.ttf');
        final response = await http.get(url).timeout(
              const Duration(seconds: 15),
              onTimeout: () => http.Response('Timeout', 408),
            );

        if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
          fontBytes = response.bodyBytes;

          // Save to local disk cache for future launches
          if (!kIsWeb) {
            try {
              final cacheFile = await _getCacheFile(page);
              await cacheFile.parent.create(recursive: true);
              await cacheFile.writeAsBytes(fontBytes, flush: true);
            } catch (e) {
              debugPrint('[QcfFontService] Error writing cache for p$page: $e');
            }
          }
        } else {
          debugPrint(
              '[QcfFontService] Failed downloading font p$page (Status: ${response.statusCode})');
          return false;
        }
      }

      // 3. Register font dynamically in Flutter's FontLoader
      final familyName = fontFamilyForPage(page);
      final fontLoader = FontLoader(familyName);
      fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
      await fontLoader.load();

      _loadedPages.add(page);
      fontLoadedNotifier.value = page;
      debugPrint('[QcfFontService] Successfully loaded QCF V2 font: $familyName');
      return true;
    } catch (e, st) {
      debugPrint('[QcfFontService] Exception loading font for page $page: $e\n$st');
      return false;
    }
  }

  Future<File> _getCacheFile(int page) async {
    final docDir = await getApplicationDocumentsDirectory();
    return File('${docDir.path}/fonts/qcf_v2/p$page.ttf');
  }
}
