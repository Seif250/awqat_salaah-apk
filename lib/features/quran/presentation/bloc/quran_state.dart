import 'package:equatable/equatable.dart';
import '../../data/models/surah_model.dart';
import '../../data/models/last_read_model.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/bookmark_collection_model.dart';

abstract class QuranState extends Equatable {
  const QuranState();

  @override
  List<Object?> get props => [];
}

class QuranInitial extends QuranState {
  const QuranInitial();
}

class QuranLoading extends QuranState {
  const QuranLoading();
}

class QuranLoaded extends QuranState {
  final List<SurahModel> allSurahs;
  final List<SurahModel> filteredSurahs;
  final LastReadModel? lastRead;
  final String searchQuery;
  final double fontSize;
  final double fontWeightValue; // 0.0 = normal, 1.0 = bold
  final bool continuousMode;
  final Set<String> bookmarks;
  final List<BookmarkModel> richBookmarks;
  final List<BookmarkCollectionModel> collections;

  const QuranLoaded({
    required this.allSurahs,
    required this.filteredSurahs,
    this.lastRead,
    this.searchQuery = '',
    this.fontSize = 23.0,
    this.fontWeightValue = 0.0,
    this.continuousMode = true,
    this.bookmarks = const {},
    this.richBookmarks = const [],
    this.collections = const [],
  });

  QuranLoaded copyWith({
    List<SurahModel>? allSurahs,
    List<SurahModel>? filteredSurahs,
    LastReadModel? lastRead,
    bool clearLastRead = false,
    String? searchQuery,
    double? fontSize,
    double? fontWeightValue,
    bool? continuousMode,
    Set<String>? bookmarks,
    List<BookmarkModel>? richBookmarks,
    List<BookmarkCollectionModel>? collections,
  }) {
    return QuranLoaded(
      allSurahs: allSurahs ?? this.allSurahs,
      filteredSurahs: filteredSurahs ?? this.filteredSurahs,
      lastRead: clearLastRead ? null : (lastRead ?? this.lastRead),
      searchQuery: searchQuery ?? this.searchQuery,
      fontSize: fontSize ?? this.fontSize,
      fontWeightValue: fontWeightValue ?? this.fontWeightValue,
      continuousMode: continuousMode ?? this.continuousMode,
      bookmarks: bookmarks ?? this.bookmarks,
      richBookmarks: richBookmarks ?? this.richBookmarks,
      collections: collections ?? this.collections,
    );
  }

  @override
  List<Object?> get props => [
        allSurahs,
        filteredSurahs,
        lastRead,
        searchQuery,
        fontSize,
        fontWeightValue,
        continuousMode,
        bookmarks,
        richBookmarks,
        collections,
      ];
}

class QuranError extends QuranState {
  final String message;
  const QuranError(this.message);

  @override
  List<Object?> get props => [message];
}

