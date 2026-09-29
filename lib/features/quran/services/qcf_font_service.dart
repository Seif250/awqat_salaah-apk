import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../data/models/quran_display_mode.dart';

/// Singleton service responsible for downloading, caching, and dynamically
/// registering Quran Foundation QCF V2 and QCF Tajweed V4 fonts into Flutter's runtime.
class QcfFontService {
  static final QcfFontService instance = QcfFontService._internal();

  QcfFontService._internal();

  static const String _v2CdnBaseUrl =
      'https://verses.quran.foundation/fonts/quran/hafs/v2/ttf';
  static const String _v4CdnBaseUrl =
      'https://verses.quran.foundation/fonts/quran/hafs/v4/colrv1/ttf';

  /// Pages whose V2 fonts have been registered.
  final Set<int> _loadedV2Pages = <int>{};

  /// Pages whose V4 Tajweed fonts have been registered.
  final Set<int> _loadedV4Pages = <int>{};

  /// In-flight loads to prevent duplicate concurrent network requests.
  final Map<String, Future<bool>> _inFlightLoads = <String, Future<bool>>{};

  /// Notifier that emits the page number whenever a font is newly loaded.
  final ValueNotifier<int> fontLoadedNotifier = ValueNotifier<int>(0);

  /// Returns the font family string to use for a given page and display mode.
  /// For normal mode: 'QCF_P{page}'.
  /// For tajweed mode: 'QCF_V4_P{page}'.
  /// When Tajweed is requested, it does not silently fall back to V2 so that
  /// the caller can distinguish between V4 active and unavailable states.
  static String fontFamilyForPage(
    int page, {
    QuranDisplayMode mode = QuranDisplayMode.normal,
  }) {
    if (mode == QuranDisplayMode.tajweed) {
      return 'QCF_V4_P$page';
    }
    return 'QCF_P$page';
  }

  /// Checks whether the font for [page] in [mode] has already been loaded into the engine.
  bool isFontLoaded(
    int page, {
    QuranDisplayMode mode = QuranDisplayMode.normal,
  }) {
    if (mode == QuranDisplayMode.tajweed) {
      return _loadedV4Pages.contains(page);
    }
    return _loadedV2Pages.contains(page);
  }

  /// Ensures that the font for [page] in [mode] is loaded into Flutter.
  /// Also triggers background prefetching for adjacent pages (page - 1, page + 1).
  Future<bool> ensurePageFont(
    int page, {
    QuranDisplayMode mode = QuranDisplayMode.normal,
  }) async {
    if (page < 1 || page > 604) return false;

    // In Tajweed mode, also make sure V2 is queued/loaded as safe fallback
    if (mode == QuranDisplayMode.tajweed && !_loadedV2Pages.contains(page)) {
      _loadFontForPage(page, QuranDisplayMode.normal);
    }

    if (isFontLoaded(page, mode: mode)) {
      _prefetchAdjacent(page, mode);
      return true;
    }

    final key = '${mode.name}_$page';
    if (_inFlightLoads.containsKey(key)) {
      return _inFlightLoads[key]!;
    }

    final future = _loadFontForPage(page, mode);
    _inFlightLoads[key] = future;

    final success = await future;
    _inFlightLoads.remove(key);

    if (success) {
      _prefetchAdjacent(page, mode);
    }

    return success;
  }

  void _prefetchAdjacent(int page, QuranDisplayMode mode) {
    if (page > 1 && !isFontLoaded(page - 1, mode: mode)) {
      final key = '${mode.name}_${page - 1}';
      if (!_inFlightLoads.containsKey(key)) {
        ensurePageFont(page - 1, mode: mode);
      }
    }
    if (page < 604 && !isFontLoaded(page + 1, mode: mode)) {
      final key = '${mode.name}_${page + 1}';
      if (!_inFlightLoads.containsKey(key)) {
        ensurePageFont(page + 1, mode: mode);
      }
    }
  }

  Future<bool> _loadFontForPage(int page, QuranDisplayMode mode) async {
    try {
      Uint8List? fontBytes;
      final isTajweed = mode == QuranDisplayMode.tajweed;
      final familyName = isTajweed ? 'QCF_V4_P$page' : 'QCF_P$page';

      // 1. Try reading from local disk cache
      if (!kIsWeb) {
        final cacheFile = await _getCacheFile(page, isTajweed: isTajweed);
        if (await cacheFile.exists()) {
          try {
            final bytes = await cacheFile.readAsBytes();
            if (bytes.length > 1000) {
              fontBytes = bytes;
            }
          } catch (e) {
            debugPrint('[QcfFontService] Error reading cache for $familyName: $e');
          }
        }
      }

      // 2. Fetch from CDN if not cached locally
      if (fontBytes == null) {
        final baseUrl = isTajweed ? _v4CdnBaseUrl : _v2CdnBaseUrl;
        final url = Uri.parse('$baseUrl/p$page.ttf');
        final response = await http.get(url).timeout(
              const Duration(seconds: 18),
              onTimeout: () => http.Response('Timeout', 408),
            );

        if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
          fontBytes = response.bodyBytes;

          // Save to local disk cache
          if (!kIsWeb) {
            try {
              final cacheFile = await _getCacheFile(page, isTajweed: isTajweed);
              await cacheFile.parent.create(recursive: true);
              await cacheFile.writeAsBytes(fontBytes, flush: true);
            } catch (e) {
              debugPrint('[QcfFontService] Error writing cache for $familyName: $e');
            }
          }
        } else {
          debugPrint(
              '[QcfFontService] Failed downloading font $familyName (Status: ${response.statusCode})');
          return false;
        }
      }

      // 3. Register font dynamically in Flutter's FontLoader
      final fontLoader = FontLoader(familyName);
      fontLoader.addFont(Future.value(ByteData.view(
        fontBytes.buffer,
        fontBytes.offsetInBytes,
        fontBytes.lengthInBytes,
      )));
      await fontLoader.load();

      if (isTajweed) {
        _loadedV4Pages.add(page);
      } else {
        _loadedV2Pages.add(page);
      }

      fontLoadedNotifier.value = 0;
      fontLoadedNotifier.value = page;
      debugPrint('[QcfFontService] Successfully loaded font: $familyName');
      return true;
    } catch (e, st) {
      debugPrint('[QcfFontService] Exception loading font for page $page ($mode): $e\n$st');
      return false;
    }
  }

  Future<File> _getCacheFile(int page, {required bool isTajweed}) async {
    final docDir = await getApplicationDocumentsDirectory();
    final folder = isTajweed ? 'qcf_v4' : 'qcf_v2';
    return File('${docDir.path}/fonts/$folder/p$page.ttf');
  }
}
