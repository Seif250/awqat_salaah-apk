import 'package:equatable/equatable.dart';
import '../../data/models/city_model.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationSuccess extends LocationState {
  final double latitude;
  final double longitude;
  final String cityName;
  final String countryName;
  final bool isAuto;
  final List<CityModel> searchResults;

  const LocationSuccess({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.countryName,
    required this.isAuto,
    this.searchResults = const [],
  });

  LocationSuccess copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? countryName,
    bool? isAuto,
    List<CityModel>? searchResults,
  }) {
    return LocationSuccess(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      isAuto: isAuto ?? this.isAuto,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        cityName,
        countryName,
        isAuto,
        searchResults,
      ];
}

class LocationPermissionDeniedState extends LocationState {
  final String message;
  const LocationPermissionDeniedState(this.message);

  @override
  List<Object?> get props => [message];
}

class LocationErrorState extends LocationState {
  final String message;
  const LocationErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
