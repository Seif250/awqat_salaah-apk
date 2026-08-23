import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/storage_service.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../../../prayer_times/presentation/pages/home_page.dart';

class OnboardingPage extends StatelessWidget {
  final StorageService storageService;

  const OnboardingPage({super.key, required this.storageService});

  void _navigateToHome(BuildContext context) async {
    await storageService.setFirstLaunchCompleted();
    if (context.mounted) {
      context.read<PrayerBloc>().add(const LoadPrayerTimesEvent());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationSuccess) {
            _navigateToHome(context);
          } else if (state is LocationPermissionDeniedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Islamic Mosque / Crescent Logo Container
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mosque_rounded,
                      size: 56,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                Text(
                  'أوقات الصلاة',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'حساب فلكي دقيق لمواقيت الصلاة الخمس مع ودجت أنيقة للشاشة الرئيسية وتنبيهات صامتة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Info Box regarding location & offline
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_bolt_rounded,
                        color: AppColors.accentGold,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'يعمل التطبيق بدون إنترنت (Offline-First) بعد تحديد موقعك لمرة واحدة.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Button 1: Current Location (GPS)
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<LocationBloc>().add(const RequestCurrentLocationEvent());
                  },
                  icon: const Icon(Icons.my_location_rounded, color: Colors.white),
                  label: const Text(
                    'استخدام الموقع الحالي (تلقائي)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 14),

                // Button 2: Manual City
                OutlinedButton.icon(
                  onPressed: () async {
                    await LocationPickerSheet.show(context);
                    if (context.mounted) {
                      _navigateToHome(context);
                    }
                  },
                  icon: const Icon(Icons.location_city_rounded, color: AppColors.accentGold),
                  label: const Text(
                    'اختيار المدينة يدوياً',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: AppColors.accentGold, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
