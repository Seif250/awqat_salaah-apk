import 'package:equatable/equatable.dart';

class CityModel extends Equatable {
  final String nameArabic;
  final String nameEnglish;
  final String countryArabic;
  final String countryEnglish;
  final double latitude;
  final double longitude;

  const CityModel({
    required this.nameArabic,
    required this.nameEnglish,
    required this.countryArabic,
    required this.countryEnglish,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
        nameArabic,
        nameEnglish,
        countryArabic,
        countryEnglish,
        latitude,
        longitude,
      ];
}
