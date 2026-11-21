import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: p.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'تحديد الموقع',
            style: AppTypography.pageTitle(p.textPrimary),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                context
                    .read<LocationBloc>()
                    .add(const RequestCurrentLocationEvent());
                Navigator.pop(context);
              },
              icon: Icon(Icons.my_location_rounded, color: p.onPrimary),
              label: Text(
                'استخدام الموقع الحالي (GPS)',
                style: AppTypography.body(p.onPrimary, weight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<LocationBloc>().add(SearchCitiesEvent(val));
              },
              style: AppTypography.body(p.textPrimary),
              decoration: InputDecoration(
                hintText: 'ابحث عن محافظة أو مدينة...',
                hintStyle: AppTypography.meta(p.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: p.textSecondary),
                filled: true,
                fillColor: p.cardElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: BlocBuilder<LocationBloc, LocationState>(
              builder: (context, state) {
                if (state is LocationSuccess) {
                  final cities = state.searchResults;
                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: cities.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: p.hairline),
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      final isSelected = city.nameArabic == state.cityName;

                      return ListTile(
                        onTap: () {
                          context
                              .read<LocationBloc>()
                              .add(SelectCityEvent(city));
                          Navigator.pop(context);
                        },
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? p.accentText : p.textSecondary,
                        ),
                        title: Text(
                          city.nameArabic,
                          style: AppTypography.rowTitle(
                            isSelected ? p.accentText : p.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${city.countryArabic} (${city.nameEnglish})',
                          style: AppTypography.meta(p.textSecondary),
                        ),
                        trailing: Text(
                          '${city.latitude.toStringAsFixed(2)}°, ${city.longitude.toStringAsFixed(2)}°',
                          style: AppTypography.badge(p.textSecondary)
                              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
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
