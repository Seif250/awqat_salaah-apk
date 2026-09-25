import 'package:equatable/equatable.dart';
import 'ayah_model.dart';

class MushafPageSegment extends Equatable {
  final int surahId;
  final String surahName;
  final bool startsSurah;
  final List<AyahModel> verses;

  const MushafPageSegment({
    required this.surahId,
    required this.surahName,
    required this.startsSurah,
    required this.verses,
  });

  @override
  List<Object?> get props => [surahId, surahName, startsSurah, verses];
}

class MushafPageModel extends Equatable {
  final int pageNumber;
  final int juz;
  final int hizb;
  final String surahName;
  final List<MushafPageSegment> segments;

  const MushafPageModel({
    required this.pageNumber,
    required this.juz,
    required this.hizb,
    required this.surahName,
    required this.segments,
  });

  @override
  List<Object?> get props => [pageNumber, juz, hizb, surahName, segments];
}
