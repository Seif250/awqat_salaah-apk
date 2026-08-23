import 'package:equatable/equatable.dart';
import '../../data/models/city_model.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class RequestCurrentLocationEvent extends LocationEvent {
  const RequestCurrentLocationEvent();
}

class SelectCityEvent extends LocationEvent {
  final CityModel city;
  const SelectCityEvent(this.city);

  @override
  List<Object?> get props => [city];
}

class SearchCitiesEvent extends LocationEvent {
  final String query;
  const SearchCitiesEvent(this.query);

  @override
  List<Object?> get props => [query];
}
