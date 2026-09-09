import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/azkar_local_data.dart';
import '../models/azkar_item_model.dart';
import '../models/custom_zikr_model.dart';
import '../models/daily_azkar_progress.dart';

class AzkarRepository {
  final SharedPreferences _prefs;

  static const String keyDailyProgress = 'azkar_daily_progress_v2';
  static const String keyCatalog = 'azkar_unified_catalog_v2';
  static const String keyCustomAzkarList = 'azkar_custom_list_v1';

  AzkarRepository(this._prefs);

  /// Get current daily progress, automatically resetting if the day changed
  DailyAzkarProgress getDailyProgress() {
    final today = DailyAzkarProgress.todayKey();
    final jsonStr = _prefs.getString(keyDailyProgress);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final savedProgress = DailyAzkarProgress.fromJson(decoded);

        // If it's still the same day, return it
        if (savedProgress.date == today) {
          return savedProgress;
        }

        // New day! Automatic daily reset: keep lifetime total, reset daily items
        final resetProgress = DailyAzkarProgress(
          date: today,
          itemCounts: const {},
          completedItemIds: const {},
          freeTasbihCount: 0,
          totalLifetimeTasbih: savedProgress.totalLifetimeTasbih,
        );
        saveDailyProgress(resetProgress);
        return resetProgress;
      } catch (_) {}
    }

    // First time
    final initial = DailyAzkarProgress(date: today);
    saveDailyProgress(initial);
    return initial;
  }

  Future<void> saveDailyProgress(DailyAzkarProgress progress) async {
    final jsonStr = jsonEncode(progress.toJson());
    await _prefs.setString(keyDailyProgress, jsonStr);
  }

  // ═══════════════════════════════════════════════════════════
  // CATALOG MANAGEMENT (Edit, Delete, Add, Restore)
  // ═══════════════════════════════════════════════════════════

  /// Get all items from the dynamic user catalog
  List<AzkarItem> getAllCatalogItems() {
    final jsonList = _prefs.getStringList(keyCatalog);
    if (jsonList != null && jsonList.isNotEmpty) {
      try {
        return jsonList
            .map((str) => AzkarItem.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Initialize with default Azkar database
    final defaults = List<AzkarItem>.from(AzkarLocalData.defaultAzkar);
    saveAllCatalogItems(defaults);
    return defaults;
  }

  Future<void> saveAllCatalogItems(List<AzkarItem> items) async {
    final jsonList = items.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(keyCatalog, jsonList);
  }

  /// Update any existing zikr (whether default or custom)
  Future<void> updateZikrItem(AzkarItem updated) async {
    final items = getAllCatalogItems();
    final index = items.indexWhere((i) => i.id == updated.id);
    if (index >= 0) {
      items[index] = updated;
    } else {
      items.insert(0, updated);
    }
    await saveAllCatalogItems(items);
  }

  /// Delete any zikr permanently from the user's catalog
  Future<void> deleteZikrItem(String id) async {
    final items = getAllCatalogItems();
    items.removeWhere((i) => i.id == id);
    await saveAllCatalogItems(items);

    // Also clean up any progress for this id
    final progress = getDailyProgress();
    final newCounts = Map<String, int>.from(progress.itemCounts)..remove(id);
    final newCompleted = Set<String>.from(progress.completedItemIds)..remove(id);
    await saveDailyProgress(progress.copyWith(
      itemCounts: newCounts,
      completedItemIds: newCompleted,
    ));
  }

  /// Restore default Azkar database
  Future<void> restoreDefaultAzkar() async {
    final defaults = List<AzkarItem>.from(AzkarLocalData.defaultAzkar);
    await saveAllCatalogItems(defaults);
  }

  /// Add new zikr (to any category)
  Future<void> addZikrItem(AzkarItem item) async {
    final items = getAllCatalogItems();
    items.removeWhere((i) => i.id == item.id);
    items.insert(0, item);
    await saveAllCatalogItems(items);
  }

  /// Get items for a given category with today's counts and completion status applied
  List<AzkarItem> getCategoryItems(
    AzkarCategory category,
    DailyAzkarProgress progress,
  ) {
    final allItems = getAllCatalogItems();

    final filtered = category == AzkarCategory.custom
        ? allItems.where((i) => i.isCustom || i.category == AzkarCategory.custom).toList()
        : allItems.where((i) => i.category == category).toList();

    return filtered.map((item) {
      final count = progress.itemCounts[item.id] ?? 0;
      final isDone = progress.completedItemIds.contains(item.id) || count >= item.targetCount;
      return item.copyWith(
        currentCount: count,
        isCompleted: isDone,
      );
    }).toList();
  }

  /// Increment count for a zikr item
  DailyAzkarProgress incrementCount(String id, int targetCount) {
    final currentProgress = getDailyProgress();
    final newCounts = Map<String, int>.from(currentProgress.itemCounts);
    final newCompleted = Set<String>.from(currentProgress.completedItemIds);

    final current = newCounts[id] ?? 0;
    final next = current + 1;
    newCounts[id] = next;

    if (next >= targetCount) {
      newCompleted.add(id);
    }

    final updated = currentProgress.copyWith(
      itemCounts: newCounts,
      completedItemIds: newCompleted,
      totalLifetimeTasbih: currentProgress.totalLifetimeTasbih + 1,
    );

    saveDailyProgress(updated);
    return updated;
  }

  /// Toggle completion state directly
  DailyAzkarProgress toggleCompletion(String id, int targetCount) {
    final currentProgress = getDailyProgress();
    final newCompleted = Set<String>.from(currentProgress.completedItemIds);
    final newCounts = Map<String, int>.from(currentProgress.itemCounts);

    if (newCompleted.contains(id)) {
      newCompleted.remove(id);
      newCounts[id] = 0;
    } else {
      newCompleted.add(id);
      newCounts[id] = targetCount;
    }

    final updated = currentProgress.copyWith(
      itemCounts: newCounts,
      completedItemIds: newCompleted,
    );

    saveDailyProgress(updated);
    return updated;
  }

  /// Reset progress for an entire category
  DailyAzkarProgress resetCategory(AzkarCategory category) {
    final currentProgress = getDailyProgress();
    final categoryItems = getCategoryItems(category, currentProgress);
    final categoryIds = categoryItems.map((e) => e.id).toSet();

    final newCounts = Map<String, int>.from(currentProgress.itemCounts)
      ..removeWhere((key, _) => categoryIds.contains(key));
    final newCompleted = Set<String>.from(currentProgress.completedItemIds)
      ..removeWhere((id) => categoryIds.contains(id));

    final updated = currentProgress.copyWith(
      itemCounts: newCounts,
      completedItemIds: newCompleted,
    );

    saveDailyProgress(updated);
    return updated;
  }

  /// Update free digital tasbih counter
  DailyAzkarProgress updateFreeTasbih(int delta) {
    final currentProgress = getDailyProgress();
    final updated = currentProgress.copyWith(
      freeTasbihCount: currentProgress.freeTasbihCount + delta,
      totalLifetimeTasbih: currentProgress.totalLifetimeTasbih + delta,
    );
    saveDailyProgress(updated);
    return updated;
  }

  /// Reset free digital tasbih counter for the day
  DailyAzkarProgress resetFreeTasbih() {
    final currentProgress = getDailyProgress();
    final updated = currentProgress.copyWith(freeTasbihCount: 0);
    saveDailyProgress(updated);
    return updated;
  }

  // ═══════════════════════════════════════════════════════════
  // LEGACY HELPER
  // ═══════════════════════════════════════════════════════════

  List<CustomZikr> getCustomAzkar() {
    return getAllCatalogItems()
        .where((i) => i.isCustom)
        .map((i) => CustomZikr(
              id: i.id,
              title: i.title,
              arabicText: i.arabicText,
              targetCount: i.targetCount,
              createdAt: DateTime.now(),
            ))
        .toList();
  }

  Future<void> addCustomZikr(CustomZikr zikr) async {
    final item = AzkarItem(
      id: zikr.id,
      category: AzkarCategory.custom,
      title: zikr.title,
      arabicText: zikr.arabicText,
      targetCount: zikr.targetCount,
      isCustom: true,
      reward: 'ذكر خاص بك',
      reference: zikr.isReminderEnabled && zikr.reminderHour != null
          ? 'تذكير يومي: ${zikr.reminderHour.toString().padLeft(2, '0')}:${(zikr.reminderMinute ?? 0).toString().padLeft(2, '0')}'
          : null,
    );
    await addZikrItem(item);
  }

  Future<void> deleteCustomZikr(String id) async {
    await deleteZikrItem(id);
  }
}
