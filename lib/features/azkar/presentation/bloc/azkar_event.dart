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
  const IncrementZikrCountEvent({required this.id, required this.targetCount});

  @override
  List<Object?> get props => [id, targetCount];
}

class ToggleZikrCompletionEvent extends AzkarEvent {
  final String id;
  final int targetCount;
  const ToggleZikrCompletionEvent({required this.id, required this.targetCount});

  @override
  List<Object?> get props => [id, targetCount];
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
