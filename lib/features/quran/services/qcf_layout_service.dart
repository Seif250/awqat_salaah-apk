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
  final Map<int, Future<QcfPageModel?>> _inFlight = <int, Future<QcfPageModel?>>{};

  /// Returns the cached model if already loaded, or null.
  QcfPageModel? getCachedPage(int page) => _cache[page];

  /// Loads and parses the QCF page layout for [page] (1..604).
  Future<QcfPageModel?> loadPage(int page) async {
    if (page < 1 || page > 604) return null;

    // Trigger font loading in parallel with layout loading
    QcfFontService.instance.ensurePageFont(page);

    if (_cache.containsKey(page)) {
      _prefetchAdjacent(page);
      return _cache[page];
    }

    if (_inFlight.containsKey(page)) {
      return _inFlight[page]!;
    }

    final future = _loadFromAsset(page);
    _inFlight[page] = future;

    final result = await future;
    _inFlight.remove(page);

    if (result != null) {
      _cache[page] = result;
      _prefetchAdjacent(page);
    }

    return result;
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

  void _prefetchAdjacent(int page) {
    if (page > 1 && !_cache.containsKey(page - 1) && !_inFlight.containsKey(page - 1)) {
      loadPage(page - 1);
    }
    if (page < 604 && !_cache.containsKey(page + 1) && !_inFlight.containsKey(page + 1)) {
      loadPage(page + 1);
    }
  }
}
