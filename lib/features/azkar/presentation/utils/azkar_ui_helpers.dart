import 'package:flutter/material.dart';
import '../../data/models/azkar_item_model.dart';

/// Helper class providing presentation-layer mappings and icons for Azkar
class AzkarUIHelpers {
  /// Maps semantic [AzkarCategory] to unified outline Material Icons
  static IconData getCategoryIcon(AzkarCategory category) {
    switch (category) {
      case AzkarCategory.morning:
        return Icons.wb_sunny_outlined;
      case AzkarCategory.evening:
        return Icons.nightlight_outlined;
      case AzkarCategory.postPrayer:
        return Icons.mosque_outlined;
      case AzkarCategory.sleep:
        return Icons.bedtime_outlined;
      case AzkarCategory.qiyam:
        return Icons.dark_mode_outlined;
      case AzkarCategory.supplications:
        return Icons.menu_book_outlined;
      case AzkarCategory.general:
        return Icons.grain_rounded;
      case AzkarCategory.custom:
        return Icons.star_outline_rounded;
    }
  }
}

/// Extension for convenient presentation access on AzkarCategory
extension AzkarCategoryUIExtension on AzkarCategory {
  IconData get categoryIcon => AzkarUIHelpers.getCategoryIcon(this);
}
