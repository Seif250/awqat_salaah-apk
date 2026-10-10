import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../data/models/quran_display_mode.dart';

/// Progress of an offline Mushaf font download: [done] of [total] pages are on disk.
class QcfDownloadProgress {
  final int done;
  final int total;
  final int failed;

  const QcfDownloadProgress({
    required this.done,
    required this.total,
    this.failed = 0,
  });

  bool get isComplete => done >= total;
}

/// Singleton service responsible for downloading, caching, and dynamically
/// registering Quran Foundation QCF V2 and QCF Tajweed V4 fonts into Flutter's runtime.
class QcfFontService {
  static final QcfFontService instance = QcfFontService._internal();

  QcfFontService._internal();

  static const int totalPages = 604;

  /// How many pages on each side of the current page are loaded in the background.
  static const int prefetchRadius = 2;

  /// Parallel requests used by [downloadAllFonts].
  static const int _downloadConcurrency = 4;

  /// Smallest byte size accepted as a real font file (guards against error pages).
  static const int _minFontBytes = 1000;

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

  /// In-flight file fetches (shared by page loads and the offline download).
  final Map<String, Future<Uint8List?>> _inFlightFetches =
      <String, Future<Uint8List?>>{};

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

  /// Ensures that the font for [page] in [mode] is loaded into Flutter, then
  /// loads the [prefetchRadius] pages on each side in the background.
  /// The prefetch never chains: only the page asked for widens the window.
  Future<bool> ensurePageFont(
    int page, {
    QuranDisplayMode mode = QuranDisplayMode.normal,
  }) async {
    final success = await _loadPage(page, mode);
    if (success) prefetchAround(page, mode: mode);
    return success;
  }

  /// Loads the fonts of the pages within [prefetchRadius] of [page], nearest first.
  void prefetchAround(
    int page, {
    QuranDisplayMode mode = QuranDisplayMode.normal,
  }) {
    for (var d = 1; d <= prefetchRadius; d++) {
      for (final p in [page + d, page - d]) {
        if (p >= 1 && p <= totalPages) _loadPage(p, mode);
      }
    }
  }

  Future<bool> _loadPage(int page, QuranDisplayMode mode) {
    if (page < 1 || page > totalPages) return Future.value(false);
    if (isFontLoaded(page, mode: mode)) return Future.value(true);

    final key = '${mode.name}_$page';
    return _inFlightLoads.putIfAbsent(
      key,
      () => _loadFontForPage(page, mode).whenComplete(() {
        _inFlightLoads.remove(key);
      }),
    );
  }

  Future<bool> _loadFontForPage(int page, QuranDisplayMode mode) async {
    final isTajweed = mode == QuranDisplayMode.tajweed;
    final familyName = fontFamilyForPage(page, mode: mode);
    try {
      final fontBytes = await _readOrDownload(page, isTajweed: isTajweed);
      if (fontBytes == null) return false;

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
      return true;
    } catch (e, st) {
      debugPrint(
          '[QcfFontService] Exception loading font for page $page ($mode): $e\n$st');
      return false;
    }
  }

  /// Returns the font file bytes for [page], from the disk cache when present,
  /// otherwise from the CDN (then written to the disk cache).
  Future<Uint8List?> _readOrDownload(int page, {required bool isTajweed}) {
    final key = '${isTajweed ? 'v4' : 'v2'}_$page';
    return _inFlightFetches.putIfAbsent(
      key,
      () => _fetchFontBytes(page, isTajweed: isTajweed).whenComplete(() {
        _inFlightFetches.remove(key);
      }),
    );
  }

  Future<Uint8List?> _fetchFontBytes(int page,
      {required bool isTajweed}) async {
    final familyName = isTajweed ? 'QCF_V4_P$page' : 'QCF_P$page';

    if (!kIsWeb) {
      try {
        final cacheFile = await _getCacheFile(page, isTajweed: isTajweed);
        if (await cacheFile.exists()) {
          final bytes = await cacheFile.readAsBytes();
          if (bytes.length > _minFontBytes) return bytes;
        }
      } catch (e) {
        debugPrint('[QcfFontService] Error reading cache for $familyName: $e');
      }
    }

    try {
      final baseUrl = isTajweed ? _v4CdnBaseUrl : _v2CdnBaseUrl;
      final url = Uri.parse('$baseUrl/p$page.ttf');
      final response = await http.get(url).timeout(
            const Duration(seconds: 18),
            onTimeout: () => http.Response('Timeout', 408),
          );

      if (response.statusCode != 200 ||
          response.bodyBytes.length <= _minFontBytes) {
        debugPrint(
            '[QcfFontService] Failed downloading font $familyName (Status: ${response.statusCode})');
        return null;
      }

      final fontBytes = response.bodyBytes;
      if (!kIsWeb) {
        try {
          final cacheFile = await _getCacheFile(page, isTajweed: isTajweed);
          await cacheFile.parent.create(recursive: true);
          // Write to a temp file first so an interrupted write never leaves a
          // truncated font that later passes the size check.
          final tmp = File('${cacheFile.path}.part');
          await tmp.writeAsBytes(fontBytes, flush: true);
          await tmp.rename(cacheFile.path);
        } catch (e) {
          debugPrint(
              '[QcfFontService] Error writing cache for $familyName: $e');
        }
      }
      return fontBytes;
    } catch (e) {
      debugPrint('[QcfFontService] Error downloading $familyName: $e');
      return null;
    }
  }

  /// Number of pages whose font for [mode] is already saved on this device.
  Future<int> countDownloadedFonts({
    QuranDisplayMode mode = QuranDisplayMode.tajweed,
  }) async {
    if (kIsWeb) return 0;
    final isTajweed = mode == QuranDisplayMode.tajweed;
    var count = 0;
    for (var page = 1; page <= totalPages; page++) {
      if (await _isCachedOnDisk(page, isTajweed: isTajweed)) count++;
    }
    return count;
  }

  /// Downloads every page font for [mode] that is not on disk yet, so the
  /// Mushaf can be read without internet. Fonts are only saved, not
  /// registered, to keep memory flat. Safe to call again to resume.
  ///
  /// Stops early when [isCancelled] returns true. Returns the final progress;
  /// `failed` counts pages that could not be downloaded in this run.
  Future<QcfDownloadProgress> downloadAllFonts({
    QuranDisplayMode mode = QuranDisplayMode.tajweed,
    void Function(QcfDownloadProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (kIsWeb) {
      return const QcfDownloadProgress(done: 0, total: totalPages);
    }
    final isTajweed = mode == QuranDisplayMode.tajweed;

    final missing = <int>[];
    for (var page = 1; page <= totalPages; page++) {
      if (!await _isCachedOnDisk(page, isTajweed: isTajweed)) missing.add(page);
    }

    var done = totalPages - missing.length;
    var failed = 0;
    onProgress?.call(QcfDownloadProgress(done: done, total: totalPages));

    var next = 0;
    Future<void> worker() async {
      while (next < missing.length) {
        if (isCancelled?.call() ?? false) return;
        final page = missing[next++];
        final bytes = await _readOrDownload(page, isTajweed: isTajweed);
        if (bytes != null &&
            await _isCachedOnDisk(page, isTajweed: isTajweed)) {
          done++;
        } else {
          failed++;
        }
        onProgress?.call(
          QcfDownloadProgress(done: done, total: totalPages, failed: failed),
        );
      }
    }

    await Future.wait(List.generate(_downloadConcurrency, (_) => worker()));
    return QcfDownloadProgress(done: done, total: totalPages, failed: failed);
  }

  /// Progress of the offline Mushaf download started with
  /// [startOfflineDownload]; null when none is running.
  final ValueNotifier<QcfDownloadProgress?> offlineDownload =
      ValueNotifier<QcfDownloadProgress?>(null);

  bool _offlineDownloadCancelled = false;

  /// Starts (or resumes) downloading all Tajweed page fonts in the background.
  /// The work keeps going when the screen that started it is closed. Returns
  /// the final progress, or null if a download is already running.
  Future<QcfDownloadProgress?> startOfflineDownload() async {
    if (offlineDownload.value != null) return null;
    _offlineDownloadCancelled = false;
    offlineDownload.value =
        const QcfDownloadProgress(done: 0, total: totalPages);
    try {
      return await downloadAllFonts(
        mode: QuranDisplayMode.tajweed,
        onProgress: (p) => offlineDownload.value = p,
        isCancelled: () => _offlineDownloadCancelled,
      );
    } finally {
      offlineDownload.value = null;
    }
  }

  void cancelOfflineDownload() => _offlineDownloadCancelled = true;

  Future<bool> _isCachedOnDisk(int page, {required bool isTajweed}) async {
    try {
      final file = await _getCacheFile(page, isTajweed: isTajweed);
      return await file.exists() && await file.length() > _minFontBytes;
    } catch (_) {
      return false;
    }
  }

  Directory? _docDir;

  Future<File> _getCacheFile(int page, {required bool isTajweed}) async {
    _docDir ??= await getApplicationDocumentsDirectory();
    final folder = isTajweed ? 'qcf_v4' : 'qcf_v2';
    return File('${_docDir!.path}/fonts/$folder/p$page.ttf');
  }
}
