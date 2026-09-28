import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// High-performance service providing authentic Medina Mushaf page images
/// (Golden Quran architecture).
/// Downloads, caches to disk, and prefetches pages in the background
/// for 60/120 FPS page turning.
class MushafImageService {
  static final MushafImageService instance = MushafImageService._internal();

  MushafImageService._internal();

  /// Primary CDN: Quran.app High-Res Medina Mushaf 1260px wide pages
  static const String _primaryCdn = 'https://files.quran.app/hafs/madani/width_1260';

  final Set<int> _cachedPages = <int>{};
  final Map<int, Future<File?>> _inFlight = <int, Future<File?>>{};
  Directory? _cacheDir;

  /// Notifier that emits the page number whenever an image is newly cached
  final ValueNotifier<int> pageImageLoadedNotifier = ValueNotifier<int>(0);

  /// Checks if page image is cached locally on disk
  bool isPageCached(int page) => _cachedPages.contains(page);

  /// Get direct CDN URL for a given page number (1 to 604)
  static String getPageImageUrl(int page) {
    final padded = page.toString().padLeft(3, '0');
    return '$_primaryCdn/page$padded.png';
  }

  Future<Directory?> _getCacheDirectory() async {
    if (kIsWeb) return null;
    if (_cacheDir != null) return _cacheDir;
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${baseDir.path}/mushaf_images_v2');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
      return dir;
    } catch (e) {
      debugPrint('[MushafImageService] Error getting cache directory: $e');
      return null;
    }
  }

  Future<File?> _getFileForPage(int page) async {
    if (kIsWeb) return null;
    final dir = await _getCacheDirectory();
    if (dir == null) return null;
    final padded = page.toString().padLeft(3, '0');
    return File('${dir.path}/page_$padded.png');
  }

  /// Synchronously returns cached File if already known to exist
  File? getCachedImageFile(int page) {
    if (kIsWeb) return null;
    if (!_cachedPages.contains(page) || _cacheDir == null) return null;
    final padded = page.toString().padLeft(3, '0');
    final file = File('${_cacheDir!.path}/page_$padded.png');
    return file.existsSync() ? file : null;
  }

  /// Ensures that the high-resolution page image is available on disk.
  /// Automatically prefetches adjacent pages (page - 1, page + 1, page + 2).
  Future<File?> ensurePageImage(int page) async {
    if (page < 1 || page > 604) return null;
    if (kIsWeb) {
      _cachedPages.add(page);
      return null;
    }

    final file = await _getFileForPage(page);
    if (file == null) return null;

    if (await file.exists() && (await file.length()) > 5000) {
      _cachedPages.add(page);
      _prefetchAdjacent(page);
      return file;
    }

    if (_inFlight.containsKey(page)) {
      return _inFlight[page]!;
    }

    final future = _downloadPageImage(page, file);
    _inFlight[page] = future;

    final result = await future;
    _inFlight.remove(page);

    if (result != null) {
      _cachedPages.add(page);
      pageImageLoadedNotifier.value = page;
      _prefetchAdjacent(page);
    }

    return result;
  }

  void _prefetchAdjacent(int page) {
    if (kIsWeb) return;
    // Prefetch next 2 pages and previous page in background without blocking
    final targets = [page + 1, page - 1, page + 2];
    for (final p in targets) {
      if (p >= 1 && p <= 604 && !_cachedPages.contains(p) && !_inFlight.containsKey(p)) {
        Future.microtask(() => ensurePageImage(p));
      }
    }
  }

  Future<File?> _downloadPageImage(int page, File targetFile) async {
    try {
      final url = Uri.parse(getPageImageUrl(page));
      final res = await http.get(url).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && res.bodyBytes.length > 5000) {
        await targetFile.writeAsBytes(res.bodyBytes, flush: true);
        return targetFile;
      }
      return null;
    } catch (e) {
      debugPrint('[MushafImageService] Error downloading page $page: $e');
      return null;
    }
  }
}
