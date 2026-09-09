import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/azkar_local_data.dart';
import '../models/azkar_item_model.dart';
import '../models/custom_zikr_model.dart';
import '../models/daily_azkar_progress.dart';

class AzkarRepository {
  final SharedPreferences _prefs;

  static const String keyDailyProgress = 'azkar_daily_progress_v1';
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

  /// Get items for a given category with today's counts and completion status applied
  List<AzkarItem> getCategoryItems(
    AzkarCategory category,
    DailyAzkarProgress progress,
  ) {
    if (category == AzkarCategory.custom) {
      final customList = getCustomAzkar();
      return customList.map((c) {
        final count = progress.itemCounts[c.id] ?? 0;
        final isDone = progress.completedItemIds.contains(c.id) || count >= c.targetCount;
        return AzkarItem(
          id: c.id,
          category: AzkarCategory.custom,
          title: c.title,
          arabicText: c.arabicText,
          reference: c.isReminderEnabled && c.reminderHour != null
              ? 'تذكير يومي: ${c.reminderHour.toString().padLeft(2, '0')}:${(c.reminderMinute ?? 0).toString().padLeft(2, '0')}'
              : null,
          reward: 'ذكر خاص بك',
          targetCount: c.targetCount,
          currentCount: count,
          isCompleted: isDone,
        );
      }).toList();
    }

    final baseItems = AzkarLocalData.defaultAzkar
        .where((item) => item.category == category)
        .toList();

    return baseItems.map((item) {
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
  // CUSTOM AZKAR STORAGE
  // ═══════════════════════════════════════════════════════════

  List<CustomZikr> getCustomAzkar() {
    final jsonList = _prefs.getStringList(keyCustomAzkarList);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList.map((itemStr) {
      try {
        final map = jsonDecode(itemStr) as Map<String, dynamic>;
        return CustomZikr.fromJson(map);
      } catch (_) {
        return null;
      }
    }).whereType<CustomZikr>().toList();
  }

  Future<void> addCustomZikr(CustomZikr zikr) async {
    final current = getCustomAzkar();
    current.removeWhere((item) => item.id == zikr.id);
    current.insert(0, zikr);

    final strList = current.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(keyCustomAzkarList, strList);
  }

  Future<void> deleteCustomZikr(String id) async {
    final current = getCustomAzkar();
    current.removeWhere((item) => item.id == id);

    final strList = current.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(keyCustomAzkarList, strList);
  }
}
