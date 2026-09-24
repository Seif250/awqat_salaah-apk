import 'package:equatable/equatable.dart';
import '../../data/models/azkar_item_model.dart';
import '../../data/models/custom_zikr_model.dart';

abstract class AzkarEvent extends Equatable {
  const AzkarEvent();

  @override
  List<Object?> get props => [];
}

class LoadAzkarEvent extends AzkarEvent {
  final AzkarCategory? category;
  const LoadAzkarEvent({this.category});

  @override
  List<Object?> get props => [category];
}

class SelectCategoryEvent extends AzkarEvent {
  final AzkarCategory category;
  const SelectCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class IncrementZikrCountEvent extends AzkarEvent {
  final String id;
  final int targetCount;
  final AzkarCategory? category;
  const IncrementZikrCountEvent({
    required this.id,
    required this.targetCount,
    this.category,
  });

  @override
  List<Object?> get props => [id, targetCount, category];
}

class ToggleZikrCompletionEvent extends AzkarEvent {
  final String id;
  final int targetCount;
  final AzkarCategory? category;
  const ToggleZikrCompletionEvent({
    required this.id,
    required this.targetCount,
    this.category,
  });

  @override
  List<Object?> get props => [id, targetCount, category];
}

class ResetCategoryProgressEvent extends AzkarEvent {
  final AzkarCategory category;
  const ResetCategoryProgressEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class AddCustomZikrEvent extends AzkarEvent {
  final CustomZikr zikr;
  const AddCustomZikrEvent(this.zikr);

  @override
  List<Object?> get props => [zikr];
}

class DeleteCustomZikrEvent extends AzkarEvent {
  final String id;
  const DeleteCustomZikrEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateFreeTasbihEvent extends AzkarEvent {
  final int delta;
  const UpdateFreeTasbihEvent(this.delta);

  @override
  List<Object?> get props => [delta];
}

class ResetFreeTasbihEvent extends AzkarEvent {
  const ResetFreeTasbihEvent();
}

class UpdateZikrItemEvent extends AzkarEvent {
  final AzkarItem item;
  const UpdateZikrItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class DeleteZikrItemEvent extends AzkarEvent {
  final String id;
  const DeleteZikrItemEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RestoreDefaultAzkarEvent extends AzkarEvent {
  const RestoreDefaultAzkarEvent();
}

class AddNewZikrItemEvent extends AzkarEvent {
  final AzkarItem item;
  const AddNewZikrItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class ImportCustomAzkarEvent extends AzkarEvent {
  final List<AzkarItem> items;
  final bool replaceExisting;

  const ImportCustomAzkarEvent({
    required this.items,
    this.replaceExisting = false,
  });

  @override
  List<Object?> get props => [items, replaceExisting];
}

class ReorderAzkarEvent extends AzkarEvent {
  final AzkarCategory category;
  final int oldIndex;
  final int newIndex;

  const ReorderAzkarEvent({
    required this.category,
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [category, oldIndex, newIndex];
}

class MoveZikrItemEvent extends AzkarEvent {
  final AzkarCategory category;
  final int fromIndex;
  final int toIndex;

  const MoveZikrItemEvent({
    required this.category,
    required this.fromIndex,
    required this.toIndex,
  });

  @override
  List<Object?> get props => [category, fromIndex, toIndex];
}
