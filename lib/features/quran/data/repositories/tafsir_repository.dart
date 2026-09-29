import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tafsir_model.dart';

/// Contract for fetching and caching Tafsir data.
abstract class TafsirRepository {
  /// Returns the available Tafsir scholarly resources (Arabic by default).
  Future<List<TafsirResource>> getAvailableTafsirs({bool forceRefresh = false});

  /// Retrieves the Tafsir text for a specific Ayah (e.g. "2:255").
  Future<Tafsir?> getTafsirForAyah({
    required String verseKey,
    required int tafsirResourceId,
  });

  /// Synchronously checks if a Tafsir entry is already cached locally.
  Tafsir? getCachedTafsir({
    required String verseKey,
    required int tafsirResourceId,
  });
}

/// Robust, offline-first implementation of [TafsirRepository].
class TafsirRepositoryImpl implements TafsirRepository {
  final SharedPreferences _prefs;
  final http.Client _client;

  static const String _apiBaseUrl = 'https://api.quran.com/api/v4';
  static const String _keyResourcesCache = 'tafsir_available_resources_v1';
  static const String _keyResourcesCacheTime = 'tafsir_available_resources_time';

  /// Standard curated Arabic Tafsir resources pre-loaded for instant offline access.
  static const List<TafsirResource> defaultArabicTafsirs = [
    TafsirResource(
      id: 16,
      name: 'التفسير الميسر',
      authorName: 'نخبة من العلماء',
      language: 'arabic',
      slug: 'ar-tafsir-muyassar',
    ),
    TafsirResource(
      id: 91,
      name: 'تفسير السعدي (تيسير الكريم الرحمن)',
      authorName: 'الشيخ عبد الرحمن بن ناصر السعدي',
      language: 'arabic',
      slug: 'ar-tafseer-al-saddi',
    ),
    TafsirResource(
      id: 14,
      name: 'تفسير ابن كثير (تفسير القرآن العظيم)',
      authorName: 'الحافظ إسماعيل بن كثير',
      language: 'arabic',
      slug: 'ar-tafsir-ibn-kathir',
    ),
    TafsirResource(
      id: 94,
      name: 'تفسير البغوي (معالم التنزيل)',
      authorName: 'الإمام الحسين بن مسعود البغوي',
      language: 'arabic',
      slug: 'ar-tafsir-al-baghawi',
    ),
    TafsirResource(
      id: 15,
      name: 'تفسير الطبري (جامع البيان)',
      authorName: 'الإمام محمد بن جرير الطبري',
      language: 'arabic',
      slug: 'ar-tafsir-al-tabari',
    ),
    TafsirResource(
      id: 90,
      name: 'تفسير القرطبي (الجامع لأحكام القرآن)',
      authorName: 'الإمام محمد بن أحمد القرطبي',
      language: 'arabic',
      slug: 'ar-tafseer-al-qurtubi',
    ),
    TafsirResource(
      id: 93,
      name: 'التفسير الوسيط',
      authorName: 'الإمام الأكبر د. محمد سيد طنطاوي',
      language: 'arabic',
      slug: 'ar-tafsir-al-wasit',
    ),
  ];

  TafsirRepositoryImpl(this._prefs, {http.Client? client})
      : _client = client ?? http.Client();

  /// Formats the local cache key according to the requirement: tafsir:{resourceId}:{verseKey}
  String _cacheKey(int resourceId, String verseKey) => 'tafsir:$resourceId:$verseKey';

  @override
  Tafsir? getCachedTafsir({
    required String verseKey,
    required int tafsirResourceId,
  }) {
    final key = _cacheKey(tafsirResourceId, verseKey);
    final rawJson = _prefs.getString(key);
    if (rawJson == null || rawJson.isEmpty) return null;

    try {
      final decoded = json.decode(rawJson) as Map<String, dynamic>;
      return Tafsir.fromJson(decoded, defaultVerseKey: verseKey);
    } catch (e) {
      debugPrint('[TafsirRepository] Failed to parse cached Tafsir for $key: $e');
      return null;
    }
  }

  @override
  Future<List<TafsirResource>> getAvailableTafsirs({bool forceRefresh = false}) async {
    // 1. Check in-memory / local cache
    if (!forceRefresh) {
      final cachedJson = _prefs.getString(_keyResourcesCache);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final list = json.decode(cachedJson) as List<dynamic>;
          final parsed = list
              .map((e) => TafsirResource.fromJson(e as Map<String, dynamic>))
              .where((r) => r.language.toLowerCase() == 'arabic')
              .toList();
          if (parsed.isNotEmpty) return parsed;
        } catch (_) {}
      }
    }

    // 2. Fetch fresh resources from authoritative Content API
    try {
      final url = Uri.parse('$_apiBaseUrl/resources/tafsirs?language=ar');
      final response = await _client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tafsirsRaw = data['tafsirs'] as List<dynamic>? ?? [];

        final List<TafsirResource> list = [];
        for (final item in tafsirsRaw) {
          final res = TafsirResource.fromJson(item as Map<String, dynamic>);
          if (res.language.toLowerCase() == 'arabic') {
            list.add(res);
          }
        }

        if (list.isNotEmpty) {
          await _prefs.setString(
            _keyResourcesCache,
            json.encode(list.map((e) => e.toJson()).toList()),
          );
          await _prefs.setInt(
            _keyResourcesCacheTime,
            DateTime.now().millisecondsSinceEpoch,
          );
          return list;
        }
      }
    } catch (e) {
      debugPrint('[TafsirRepository] Error fetching remote tafsir resources: $e');
    }

    // 3. Fallback to default curated Arabic resources
    return defaultArabicTafsirs;
  }

  @override
  Future<Tafsir?> getTafsirForAyah({
    required String verseKey,
    required int tafsirResourceId,
  }) async {
    // 1. Check local cache first (Offline-first)
    final cached = getCachedTafsir(
      verseKey: verseKey,
      tafsirResourceId: tafsirResourceId,
    );
    if (cached != null && cached.text.isNotEmpty) {
      return cached;
    }

    // 2. Fetch from authoritative Quran Content API
    try {
      final url = Uri.parse('$_apiBaseUrl/tafsirs/$tafsirResourceId/by_ayah/$verseKey');
      final response = await _client.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final tafsirJson = decoded['tafsir'];

        if (tafsirJson is Map<String, dynamic>) {
          final rawText = tafsirJson['text'] as String? ?? '';
          final cleanText = cleanTafsirHtml(rawText);

          final tafsir = Tafsir(
            verseKey: verseKey,
            resourceId: tafsirResourceId,
            resourceName: _resolveResourceName(tafsirJson, tafsirResourceId),
            text: cleanText,
          );

          // 3. Persist in local storage
          await _prefs.setString(
            _cacheKey(tafsirResourceId, verseKey),
            json.encode(tafsir.toJson()),
          );

          return tafsir;
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TafsirRepository] Failed to fetch Tafsir for $verseKey ($tafsirResourceId): $e');
      // If we had an expired or partial cache, return it; otherwise rethrow so UI handles offline state
      if (cached != null) return cached;
      rethrow;
    }

    return null;
  }

  String _resolveResourceName(Map<String, dynamic> json, int resourceId) {
    final translatedName = json['translated_name'];
    if (translatedName is Map && translatedName['name'] != null) {
      final name = translatedName['name'].toString().trim();
      if (name.isNotEmpty) return name;
    }
    final resName = json['resource_name']?.toString().trim();
    if (resName != null && resName.isNotEmpty) return resName;

    final defaultMatch = defaultArabicTafsirs.where((r) => r.id == resourceId);
    if (defaultMatch.isNotEmpty) return defaultMatch.first.name;

    return 'تفسير الآية';
  }

  /// Cleans HTML tags, span markers, and unescapes entities for optimal Arabic typography.
  static String cleanTafsirHtml(String html) {
    if (html.isEmpty) return '';

    String cleaned = html;

    // Handle line breaks and paragraphs
    cleaned = cleaned.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    cleaned = cleaned.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');

    // Strip other tags (spans, divs, strong, em, etc.) while preserving inner text
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');

    // Unescape common HTML entities
    cleaned = cleaned
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&rlm;', '')
        .replaceAll('&lrm;', '');

    // Clean up multiple excessive line breaks
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }
}
