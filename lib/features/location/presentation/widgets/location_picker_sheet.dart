import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LocationBloc>(),
        child: const LocationPickerSheet(),
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'تحديد الموقع',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // GPS Location Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<LocationBloc>().add(const RequestCurrentLocationEvent());
                Navigator.pop(context);
              },
              icon: const Icon(Icons.my_location_rounded, color: Colors.white),
              label: const Text(
                'استخدام الموقع الحالي (GPS)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<LocationBloc>().add(SearchCitiesEvent(val));
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن محافظة أو مدينة...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // City List
          Expanded(
            child: BlocBuilder<LocationBloc, LocationState>(
              builder: (context, state) {
                if (state is LocationSuccess) {
                  final cities = state.searchResults;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: cities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      final isSelected = city.nameArabic == state.cityName;

                      return ListTile(
                        onTap: () {
                          context.read<LocationBloc>().add(SelectCityEvent(city));
                          Navigator.pop(context);
                        },
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.accentGold : Colors.grey,
                        ),
                        title: Text(
                          city.nameArabic,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.accentGold : null,
                          ),
                        ),
                        subtitle: Text('${city.countryArabic} (${city.nameEnglish})'),
                        trailing: Text(
                          '${city.latitude.toStringAsFixed(2)}°, ${city.longitude.toStringAsFixed(2)}°',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
