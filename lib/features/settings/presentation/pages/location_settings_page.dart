import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../../../prayer_times/presentation/bloc/prayer_state.dart';

class LocationSettingsPage extends StatelessWidget {
  const LocationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الموقع الجغرافي'),
        centerTitle: true,
      ),
      body: BlocBuilder<PrayerBloc, PrayerState>(
        builder: (context, state) {
          String cityName = 'جاري التحديد...';
          String countryName = '';
          if (state is PrayerLoaded) {
            cityName = state.cityName;
            countryName = state.countryName;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Current Location Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF132F23), const Color(0xFF0C1D16)]
                        : [AppColors.primary, const Color(0xFF1B6A43)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 32,
                        color: AppColors.accentGold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الموقع الحالي',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (countryName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        countryName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF13231B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_location_alt_outlined, color: AppColors.accentGold),
                      title: const Text('تغيير المدينة أو البحث بالاسم', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('اختيار من قائمة المدن أو البحث المباشر'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () async {
                        await LocationPickerSheet.show(context);
                        if (context.mounted) {
                          context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Informative Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'يتم حساب أوقات الصلاة بناءً على الإحداثيات الجغرافية لمدينتك بدقة فلكية عالية دون الحاجة للاتصال الدائم بالإنترنت.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
