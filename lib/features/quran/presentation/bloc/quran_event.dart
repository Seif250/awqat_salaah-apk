import 'package:equatable/equatable.dart';
import '../../data/models/last_read_model.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/bookmark_collection_model.dart';

abstract class QuranEvent extends Equatable {
  const QuranEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuranEvent extends QuranEvent {
  const LoadQuranEvent();
}

class SearchQuranEvent extends QuranEvent {
  final String query;
  const SearchQuranEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class UpdateLastReadEvent extends QuranEvent {
  final LastReadModel lastRead;
  const UpdateLastReadEvent(this.lastRead);

  @override
  List<Object?> get props => [lastRead];
}

class ChangeFontSizeEvent extends QuranEvent {
  final double size;
  const ChangeFontSizeEvent(this.size);

  @override
  List<Object?> get props => [size];
}

class ChangeFontWeightEvent extends QuranEvent {
  final double weight;
  const ChangeFontWeightEvent(this.weight);

  @override
  List<Object?> get props => [weight];
}

class ToggleContinuousModeEvent extends QuranEvent {
  final bool continuous;
  const ToggleContinuousModeEvent(this.continuous);

  @override
  List<Object?> get props => [continuous];
}

class ToggleBookmarkEvent extends QuranEvent {
  final int surahId;
  final int ayahId;
  final String color;
  final String? note;
  final List<String> collectionIds;

  const ToggleBookmarkEvent(
    this.surahId,
    this.ayahId, {
    this.color = '#D4AF37',
    this.note,
    this.collectionIds = const [],
  });

  @override
  List<Object?> get props => [surahId, ayahId, color, note, collectionIds];
}

class SaveRichBookmarkEvent extends QuranEvent {
  final BookmarkModel bookmark;
  const SaveRichBookmarkEvent(this.bookmark);

  @override
  List<Object?> get props => [bookmark];
}

class DeleteRichBookmarkEvent extends QuranEvent {
  final int surahId;
  final int ayahId;
  const DeleteRichBookmarkEvent(this.surahId, this.ayahId);

  @override
  List<Object?> get props => [surahId, ayahId];
}

class UpdateBookmarkColorEvent extends QuranEvent {
  final int surahId;
  final int ayahId;
  final String color;
  const UpdateBookmarkColorEvent(this.surahId, this.ayahId, this.color);

  @override
  List<Object?> get props => [surahId, ayahId, color];
}

class UpdateBookmarkNoteEvent extends QuranEvent {
  final int surahId;
  final int ayahId;
  final String? note;
  const UpdateBookmarkNoteEvent(this.surahId, this.ayahId, this.note);

  @override
  List<Object?> get props => [surahId, ayahId, note];
}

class AddAyahToCollectionEvent extends QuranEvent {
  final int surahId;
  final int ayahId;
  final String collectionId;
  const AddAyahToCollectionEvent(this.surahId, this.ayahId, this.collectionId);

  @override
  List<Object?> get props => [surahId, ayahId, collectionId];
}

class RemoveAyahFromCollectionEvent extends QuranEvent {
  final int surahId;
  final int ayahId;
  final String collectionId;
  const RemoveAyahFromCollectionEvent(this.surahId, this.ayahId, this.collectionId);

  @override
  List<Object?> get props => [surahId, ayahId, collectionId];
}

class BookmarkMultipleAyatEvent extends QuranEvent {
  final List<({int surahId, int ayahId, int page})> ayat;
  final String? collectionId;
  final String color;

  const BookmarkMultipleAyatEvent(
    this.ayat, {
    this.collectionId,
    this.color = '#D4AF37',
  });

  @override
  List<Object?> get props => [ayat, collectionId, color];
}

class SaveBookmarkCollectionEvent extends QuranEvent {
  final BookmarkCollectionModel collection;
  const SaveBookmarkCollectionEvent(this.collection);

  @override
  List<Object?> get props => [collection];
}

class DeleteBookmarkCollectionEvent extends QuranEvent {
  final String collectionId;
  const DeleteBookmarkCollectionEvent(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

