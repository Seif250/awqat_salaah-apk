import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/storage_service.dart';
import '../../data/repositories/location_repository_impl.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _locationRepository;
  final StorageService _storageService;

  LocationBloc({
    required LocationRepository locationRepository,
    required StorageService storageService,
  })  : _locationRepository = locationRepository,
        _storageService = storageService,
        super(LocationSuccess(
          latitude: storageService.latitude,
          longitude: storageService.longitude,
          cityName: storageService.cityName,
          countryName: storageService.countryName,
          isAuto: storageService.isAutoLocation,
          searchResults: LocationRepository.defaultCities,
        )) {
    on<RequestCurrentLocationEvent>(_onRequestCurrentLocation);
    on<SelectCityEvent>(_onSelectCity);
    on<SearchCitiesEvent>(_onSearchCities);
  }

  Future<void> _onRequestCurrentLocation(
    RequestCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      final position = await _locationRepository.getCurrentPosition();
      if (position != null) {
        final cityName = await _locationRepository.getCityNameFromCoordinates(
          position.latitude,
          position.longitude,
        );

        await _storageService.setLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          cityName: cityName,
          countryName: 'مصر',
          isAuto: true,
        );

        emit(LocationSuccess(
          latitude: position.latitude,
          longitude: position.longitude,
          cityName: cityName,
          countryName: 'مصر',
          isAuto: true,
          searchResults: LocationRepository.defaultCities,
        ));
      } else {
        emit(const LocationPermissionDeniedState(
          'تعذر الحصول على الموقع. يرجى تفعيل إذن الموقع أو اختيار المدينة يدوياً.',
        ));
      }
    } catch (e) {
      emit(LocationErrorState(e.toString()));
    }
  }

  Future<void> _onSelectCity(
    SelectCityEvent event,
    Emitter<LocationState> emit,
  ) async {
    await _storageService.setLocation(
      latitude: event.city.latitude,
      longitude: event.city.longitude,
      cityName: event.city.nameArabic,
      countryName: event.city.countryArabic,
      isAuto: false,
    );

    emit(LocationSuccess(
      latitude: event.city.latitude,
      longitude: event.city.longitude,
      cityName: event.city.nameArabic,
      countryName: event.city.countryArabic,
      isAuto: false,
      searchResults: LocationRepository.defaultCities,
    ));
  }

  void _onSearchCities(
    SearchCitiesEvent event,
    Emitter<LocationState> emit,
  ) {
    if (state is LocationSuccess) {
      final current = state as LocationSuccess;
      final results = _locationRepository.searchCities(event.query);
      emit(current.copyWith(searchResults: results));
    }
  }
}
