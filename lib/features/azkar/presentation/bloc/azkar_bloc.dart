import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/azkar_item_model.dart';
import '../../data/models/custom_zikr_model.dart';
import '../../data/models/daily_azkar_progress.dart';
import '../../data/repositories/azkar_repository.dart';
import 'azkar_event.dart';
import 'azkar_state.dart';

class AzkarBloc extends Bloc<AzkarEvent, AzkarState> {
  final AzkarRepository repository;

  AzkarBloc({required this.repository}) : super(const AzkarInitial()) {
    on<LoadAzkarEvent>(_onLoadAzkar);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<IncrementZikrCountEvent>(_onIncrementCount);
    on<ToggleZikrCompletionEvent>(_onToggleCompletion);
    on<ResetCategoryProgressEvent>(_onResetCategory);
    on<AddCustomZikrEvent>(_onAddCustomZikr);
    on<DeleteCustomZikrEvent>(_onDeleteCustomZikr);
    on<UpdateFreeTasbihEvent>(_onUpdateFreeTasbih);
    on<ResetFreeTasbihEvent>(_onResetFreeTasbih);
    on<UpdateZikrItemEvent>(_onUpdateZikrItem);
    on<DeleteZikrItemEvent>(_onDeleteZikrItem);
    on<RestoreDefaultAzkarEvent>(_onRestoreDefaultAzkar);
    on<AddNewZikrItemEvent>(_onAddNewZikrItem);
    on<ImportCustomAzkarEvent>(_onImportCustomAzkar);
    on<ReorderAzkarEvent>(_onReorderAzkar);
  }

  AzkarCategory _defaultCategoryForCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return AzkarCategory.morning;
    } else if (hour >= 12 && hour < 19) {
      return AzkarCategory.evening;
    } else if (hour >= 19 && hour <= 23) {
      return AzkarCategory.sleep;
    } else {
      return AzkarCategory.qiyam;
    }
  }

  void _onLoadAzkar(LoadAzkarEvent event, Emitter<AzkarState> emit) {
    try {
      final category = event.category ?? _defaultCategoryForCurrentTime();
      final progress = repository.getDailyProgress();
      final customAzkar = repository.getCustomAzkar();
      final items = repository.getCategoryItems(category, progress);

      emit(_buildLoadedState(
        selectedCategory: category,
        items: items,
        progress: progress,
        customAzkar: customAzkar,
      ));
    } catch (e) {
      emit(AzkarError('فشل تحميل الأذكار: $e'));
    }
  }

  void _onSelectCategory(SelectCategoryEvent event, Emitter<AzkarState> emit) {
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final items = repository.getCategoryItems(event.category, progress);

    emit(_buildLoadedState(
      selectedCategory: event.category,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  void _onIncrementCount(IncrementZikrCountEvent event, Emitter<AzkarState> emit) {
    if (state is! AzkarLoaded) return;
    final current = state as AzkarLoaded;

    final updatedProgress = repository.incrementCount(event.id, event.targetCount);
    final items = repository.getCategoryItems(current.selectedCategory, updatedProgress);

    emit(_buildLoadedState(
      selectedCategory: current.selectedCategory,
      items: items,
      progress: updatedProgress,
      customAzkar: current.customAzkar,
    ));
  }

  void _onToggleCompletion(ToggleZikrCompletionEvent event, Emitter<AzkarState> emit) {
    if (state is! AzkarLoaded) return;
    final current = state as AzkarLoaded;

    final updatedProgress = repository.toggleCompletion(event.id, event.targetCount);
    final items = repository.getCategoryItems(current.selectedCategory, updatedProgress);

    emit(_buildLoadedState(
      selectedCategory: current.selectedCategory,
      items: items,
      progress: updatedProgress,
      customAzkar: current.customAzkar,
    ));
  }

  void _onResetCategory(ResetCategoryProgressEvent event, Emitter<AzkarState> emit) {
    if (state is! AzkarLoaded) return;
    final current = state as AzkarLoaded;

    final updatedProgress = repository.resetCategory(event.category);
    final items = repository.getCategoryItems(event.category, updatedProgress);

    emit(_buildLoadedState(
      selectedCategory: event.category,
      items: items,
      progress: updatedProgress,
      customAzkar: current.customAzkar,
    ));
  }

  Future<void> _onAddCustomZikr(AddCustomZikrEvent event, Emitter<AzkarState> emit) async {
    await repository.addCustomZikr(event.zikr);
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final currentCategory = state is AzkarLoaded
        ? (state as AzkarLoaded).selectedCategory
        : AzkarCategory.custom;
    final items = repository.getCategoryItems(currentCategory, progress);

    emit(_buildLoadedState(
      selectedCategory: currentCategory,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  Future<void> _onDeleteCustomZikr(DeleteCustomZikrEvent event, Emitter<AzkarState> emit) async {
    await repository.deleteCustomZikr(event.id);
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final currentCategory = state is AzkarLoaded
        ? (state as AzkarLoaded).selectedCategory
        : AzkarCategory.custom;
    final items = repository.getCategoryItems(currentCategory, progress);

    emit(_buildLoadedState(
      selectedCategory: currentCategory,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  void _onUpdateFreeTasbih(UpdateFreeTasbihEvent event, Emitter<AzkarState> emit) {
    if (state is! AzkarLoaded) return;
    final current = state as AzkarLoaded;

    final updatedProgress = repository.updateFreeTasbih(event.delta);

    emit(current.copyWith(dailyProgress: updatedProgress));
  }

  void _onResetFreeTasbih(ResetFreeTasbihEvent event, Emitter<AzkarState> emit) {
    if (state is! AzkarLoaded) return;
    final current = state as AzkarLoaded;

    final updatedProgress = repository.resetFreeTasbih();

    emit(current.copyWith(dailyProgress: updatedProgress));
  }

  Future<void> _onUpdateZikrItem(UpdateZikrItemEvent event, Emitter<AzkarState> emit) async {
    await repository.updateZikrItem(event.item);
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final currentCategory = state is AzkarLoaded
        ? (state as AzkarLoaded).selectedCategory
        : event.item.category;
    final items = repository.getCategoryItems(currentCategory, progress);

    emit(_buildLoadedState(
      selectedCategory: currentCategory,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  Future<void> _onDeleteZikrItem(DeleteZikrItemEvent event, Emitter<AzkarState> emit) async {
    await repository.deleteZikrItem(event.id);
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final currentCategory = state is AzkarLoaded
        ? (state as AzkarLoaded).selectedCategory
        : AzkarCategory.morning;
    final items = repository.getCategoryItems(currentCategory, progress);

    emit(_buildLoadedState(
      selectedCategory: currentCategory,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  Future<void> _onRestoreDefaultAzkar(RestoreDefaultAzkarEvent event, Emitter<AzkarState> emit) async {
    await repository.restoreDefaultAzkar();
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final currentCategory = state is AzkarLoaded
        ? (state as AzkarLoaded).selectedCategory
        : AzkarCategory.morning;
    final items = repository.getCategoryItems(currentCategory, progress);

    emit(_buildLoadedState(
      selectedCategory: currentCategory,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  Future<void> _onAddNewZikrItem(AddNewZikrItemEvent event, Emitter<AzkarState> emit) async {
    await repository.addZikrItem(event.item);
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final currentCategory = event.item.category;
    final items = repository.getCategoryItems(currentCategory, progress);

    emit(_buildLoadedState(
      selectedCategory: currentCategory,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  Future<void> _onImportCustomAzkar(ImportCustomAzkarEvent event, Emitter<AzkarState> emit) async {
    await repository.importCustomAzkar(event.items, replaceExisting: event.replaceExisting);
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    // After importing custom Azkar, switch directly to the custom category to view them
    final items = repository.getCategoryItems(AzkarCategory.custom, progress);

    emit(_buildLoadedState(
      selectedCategory: AzkarCategory.custom,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  Future<void> _onReorderAzkar(ReorderAzkarEvent event, Emitter<AzkarState> emit) async {
    await repository.reorderCategoryItems(event.category, event.oldIndex, event.newIndex);
    final progress = repository.getDailyProgress();
    final customAzkar = repository.getCustomAzkar();
    final items = repository.getCategoryItems(event.category, progress);

    emit(_buildLoadedState(
      selectedCategory: event.category,
      items: items,
      progress: progress,
      customAzkar: customAzkar,
    ));
  }

  AzkarLoaded _buildLoadedState({
    required AzkarCategory selectedCategory,
    required List<AzkarItem> items,
    required DailyAzkarProgress progress,
    required List<CustomZikr> customAzkar,
  }) {
    final completedCategoryCount = items.where((e) => e.isCompleted).length;
    final totalCategoryCount = items.length;
    final categoryRate = totalCategoryCount > 0
        ? completedCategoryCount / totalCategoryCount
        : 0.0;

    // Morning rate
    final morningItems = repository.getCategoryItems(AzkarCategory.morning, progress);
    final morningDone = morningItems.where((e) => e.isCompleted).length;
    final morningRate = morningItems.isNotEmpty ? morningDone / morningItems.length : 0.0;

    // Evening rate
    final eveningItems = repository.getCategoryItems(AzkarCategory.evening, progress);
    final eveningDone = eveningItems.where((e) => e.isCompleted).length;
    final eveningRate = eveningItems.isNotEmpty ? eveningDone / eveningItems.length : 0.0;

    return AzkarLoaded(
      selectedCategory: selectedCategory,
      currentItems: items,
      dailyProgress: progress,
      customAzkar: customAzkar,
      categoryCompletionRate: categoryRate,
      morningCompletionRate: morningRate,
      eveningCompletionRate: eveningRate,
      completedCategoryCount: completedCategoryCount,
      totalCategoryCount: totalCategoryCount,
    );
  }
}
