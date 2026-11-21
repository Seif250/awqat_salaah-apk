import 'package:equatable/equatable.dart';
import '../../data/models/azkar_item_model.dart';
import '../../data/models/custom_zikr_model.dart';
import '../../data/models/daily_azkar_progress.dart';

abstract class AzkarState extends Equatable {
  const AzkarState();

  @override
  List<Object?> get props => [];
}

class AzkarInitial extends AzkarState {
  const AzkarInitial();
}

class AzkarLoading extends AzkarState {
  const AzkarLoading();
}

class AzkarLoaded extends AzkarState {
  final AzkarCategory selectedCategory;
  final List<AzkarItem> currentItems;
  final DailyAzkarProgress dailyProgress;
  final List<CustomZikr> customAzkar;

  // Computed helper metrics & reading preferences
  final double categoryCompletionRate;
  final double morningCompletionRate;
  final double eveningCompletionRate;
  final int completedCategoryCount;
  final int totalCategoryCount;
  final double fontScale;
  final Set<AzkarCategory> completedCategories;

  const AzkarLoaded({
    required this.selectedCategory,
    required this.currentItems,
    required this.dailyProgress,
    required this.customAzkar,
    required this.categoryCompletionRate,
    required this.morningCompletionRate,
    required this.eveningCompletionRate,
    required this.completedCategoryCount,
    required this.totalCategoryCount,
    this.fontScale = 1.0,
    this.completedCategories = const {},
  });

  AzkarLoaded copyWith({
    AzkarCategory? selectedCategory,
    List<AzkarItem>? currentItems,
    DailyAzkarProgress? dailyProgress,
    List<CustomZikr>? customAzkar,
    double? categoryCompletionRate,
    double? morningCompletionRate,
    double? eveningCompletionRate,
    int? completedCategoryCount,
    int? totalCategoryCount,
    double? fontScale,
    Set<AzkarCategory>? completedCategories,
  }) {
    return AzkarLoaded(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentItems: currentItems ?? this.currentItems,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      customAzkar: customAzkar ?? this.customAzkar,
      categoryCompletionRate: categoryCompletionRate ?? this.categoryCompletionRate,
      morningCompletionRate: morningCompletionRate ?? this.morningCompletionRate,
      eveningCompletionRate: eveningCompletionRate ?? this.eveningCompletionRate,
      completedCategoryCount: completedCategoryCount ?? this.completedCategoryCount,
      totalCategoryCount: totalCategoryCount ?? this.totalCategoryCount,
      fontScale: fontScale ?? this.fontScale,
      completedCategories: completedCategories ?? this.completedCategories,
    );
  }

  @override
  List<Object?> get props => [
        selectedCategory,
        currentItems,
        dailyProgress,
        customAzkar,
        categoryCompletionRate,
        morningCompletionRate,
        eveningCompletionRate,
        completedCategoryCount,
        totalCategoryCount,
        fontScale,
        completedCategories,
      ];
}

class AzkarError extends AzkarState {
  final String message;
  const AzkarError(this.message);

  @override
  List<Object?> get props => [message];
}
