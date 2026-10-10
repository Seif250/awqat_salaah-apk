import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/models/qcf_page_model.dart';
import 'qcf_font_service.dart';

/// Service responsible for loading and caching the official 604-page
/// deterministic QCF V2 layout models from assets.
class QcfLayoutService {
  static final QcfLayoutService instance = QcfLayoutService._internal();

  QcfLayoutService._internal();

  final Map<int, QcfPageModel> _cache = <int, QcfPageModel>{};
  final Map<int, Future<QcfPageModel?>> _inFlight =
      <int, Future<QcfPageModel?>>{};

  /// Returns the cached model if already loaded, or null.
  QcfPageModel? getCachedPage(int page) => _cache[page];

  /// Loads and parses the QCF page layout for [page] (1..604), then loads the
  /// neighbouring layouts in the background. The prefetch never chains.
  Future<QcfPageModel?> loadPage(int page) async {
    final result = await _load(page);
    if (result != null) {
      final radius = QcfFontService.prefetchRadius;
      for (var d = 1; d <= radius; d++) {
        _load(page + d);
        _load(page - d);
      }
    }
    return result;
  }

  Future<QcfPageModel?> _load(int page) {
    if (page < 1 || page > 604) return Future.value(null);
    final cached = _cache[page];
    if (cached != null) return Future.value(cached);

    return _inFlight.putIfAbsent(
      page,
      () => _loadFromAsset(page).then((result) {
        if (result != null) _cache[page] = result;
        return result;
      }).whenComplete(() {
        _inFlight.remove(page);
      }),
    );
  }

  Future<QcfPageModel?> _loadFromAsset(int page) async {
    try {
      final padded = page.toString().padLeft(3, '0');
      final assetPath = 'assets/data/qcf_pages/page-$padded.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return QcfPageModel.fromJson(jsonMap);
    } catch (e) {
      debugPrint('[QcfLayoutService] Error loading page $page: $e');
      return null;
    }
  }
}
