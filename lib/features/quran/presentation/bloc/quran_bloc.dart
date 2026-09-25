import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/quran_repository.dart';
import 'quran_event.dart';
import 'quran_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final QuranRepository repository;

  QuranBloc({required this.repository}) : super(const QuranInitial()) {
    on<LoadQuranEvent>(_onLoadQuran);
    on<SearchQuranEvent>(_onSearchQuran);
    on<UpdateLastReadEvent>(_onUpdateLastRead);
    on<ChangeFontSizeEvent>(_onChangeFontSize);
    on<ChangeFontWeightEvent>(_onChangeFontWeight);
    on<ToggleContinuousModeEvent>(_onToggleContinuousMode);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
    on<SaveRichBookmarkEvent>(_onSaveRichBookmark);
    on<DeleteRichBookmarkEvent>(_onDeleteRichBookmark);
    on<UpdateBookmarkColorEvent>(_onUpdateBookmarkColor);
    on<UpdateBookmarkNoteEvent>(_onUpdateBookmarkNote);
    on<AddAyahToCollectionEvent>(_onAddAyahToCollection);
    on<RemoveAyahFromCollectionEvent>(_onRemoveAyahFromCollection);
    on<BookmarkMultipleAyatEvent>(_onBookmarkMultipleAyat);
    on<SaveBookmarkCollectionEvent>(_onSaveBookmarkCollection);
    on<DeleteBookmarkCollectionEvent>(_onDeleteBookmarkCollection);
  }

  Future<void> _onLoadQuran(
    LoadQuranEvent event,
    Emitter<QuranState> emit,
  ) async {
    emit(const QuranLoading());
    try {
      final surahs = await repository.loadQuran();
      final lastRead = repository.getLastRead();
      final fontSize = repository.getFontSize();
      final fontWeight = repository.getFontWeight();
      final continuous = repository.isContinuousMode();
      final bookmarks = repository.getBookmarks();
      final richBookmarks = repository.getRichBookmarks();
      final collections = repository.getCollections();

      emit(QuranLoaded(
        allSurahs: surahs,
        filteredSurahs: surahs,
        lastRead: lastRead,
        fontSize: fontSize,
        fontWeightValue: fontWeight,
        continuousMode: continuous,
        bookmarks: bookmarks,
        richBookmarks: richBookmarks,
        collections: collections,
      ));
    } catch (e) {
      emit(QuranError('فشل تحميل بيانات المصحف الشريف: ${e.toString()}'));
    }
  }

  void _onSearchQuran(
    SearchQuranEvent event,
    Emitter<QuranState> emit,
  ) {
    final currentState = state;
    if (currentState is! QuranLoaded) return;

    final query = event.query.trim();
    if (query.isEmpty) {
      emit(currentState.copyWith(
        filteredSurahs: currentState.allSurahs,
        searchQuery: '',
      ));
    } else {
      final filtered = repository.searchSurahs(query);
      emit(currentState.copyWith(
        filteredSurahs: filtered,
        searchQuery: query,
      ));
    }
  }

  Future<void> _onUpdateLastRead(
    UpdateLastReadEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.saveLastRead(event.lastRead);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(lastRead: event.lastRead));
    }
  }

  Future<void> _onChangeFontSize(
    ChangeFontSizeEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.setFontSize(event.size);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(fontSize: event.size));
    }
  }

  Future<void> _onChangeFontWeight(
    ChangeFontWeightEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.setFontWeight(event.weight);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(fontWeightValue: event.weight));
    }
  }

  Future<void> _onToggleContinuousMode(
    ToggleContinuousModeEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.setContinuousMode(event.continuous);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(continuousMode: event.continuous));
    }
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.toggleBookmark(
      event.surahId,
      event.ayahId,
      color: event.color,
      note: event.note,
      collectionIds: event.collectionIds,
    );
    final currentState = state;
    if (currentState is QuranLoaded) {
      final updatedBookmarks = repository.getBookmarks();
      final updatedRich = repository.getRichBookmarks();
      emit(currentState.copyWith(
        bookmarks: updatedBookmarks,
        richBookmarks: updatedRich,
      ));
    }
  }

  Future<void> _onSaveRichBookmark(
    SaveRichBookmarkEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.saveRichBookmark(event.bookmark);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        bookmarks: repository.getBookmarks(),
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onDeleteRichBookmark(
    DeleteRichBookmarkEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.removeRichBookmark(event.surahId, event.ayahId);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        bookmarks: repository.getBookmarks(),
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onUpdateBookmarkColor(
    UpdateBookmarkColorEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.updateBookmarkColor(event.surahId, event.ayahId, event.color);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onUpdateBookmarkNote(
    UpdateBookmarkNoteEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.updateBookmarkNote(event.surahId, event.ayahId, event.note);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onAddAyahToCollection(
    AddAyahToCollectionEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.addAyahToCollection(event.surahId, event.ayahId, event.collectionId);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        bookmarks: repository.getBookmarks(),
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onRemoveAyahFromCollection(
    RemoveAyahFromCollectionEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.removeAyahFromCollection(event.surahId, event.ayahId, event.collectionId);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onBookmarkMultipleAyat(
    BookmarkMultipleAyatEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.bookmarkMultipleAyat(
      event.ayat,
      collectionId: event.collectionId,
      color: event.color,
    );
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        bookmarks: repository.getBookmarks(),
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onSaveBookmarkCollection(
    SaveBookmarkCollectionEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.saveCollection(event.collection);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        collections: repository.getCollections(),
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }

  Future<void> _onDeleteBookmarkCollection(
    DeleteBookmarkCollectionEvent event,
    Emitter<QuranState> emit,
  ) async {
    await repository.deleteCollection(event.collectionId);
    final currentState = state;
    if (currentState is QuranLoaded) {
      emit(currentState.copyWith(
        collections: repository.getCollections(),
        richBookmarks: repository.getRichBookmarks(),
      ));
    }
  }
}

