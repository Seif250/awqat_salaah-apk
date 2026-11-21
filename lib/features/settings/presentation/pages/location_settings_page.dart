import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../../../prayer_times/presentation/bloc/prayer_state.dart';

class LocationSettingsPage extends StatelessWidget {
  const LocationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text('الموقع الجغرافي', style: AppTypography.pageTitle(p.textPrimary)),
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
              // Single hero location banner harmonized with palette
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.onPrimary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 30,
                        color: p.accentLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الموقع الحالي',
                      style: AppTypography.meta(p.onPrimary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cityName,
                      style: AppTypography.heroTitle(p.onPrimary),
                      textAlign: TextAlign.center,
                    ),
                    if (countryName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        countryName,
                        style: AppTypography.body(p.onPrimary.withValues(alpha: 0.88)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Open row action separated by hairline (not boxed card)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: p.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_location_alt_outlined, color: p.accentText, size: 20),
                ),
                title: Text('تغيير المدينة أو البحث بالاسم', style: AppTypography.rowTitle(p.textPrimary)),
                subtitle: Text('اختيار من قائمة المدن أو البحث المباشر', style: AppTypography.meta(p.textSecondary)),
                trailing: Icon(Icons.chevron_left_rounded, color: p.textSecondary),
                onTap: () async {
                  await LocationPickerSheet.show(context);
                  if (context.mounted) {
                    context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                  }
                },
              ),
              Divider(height: 1, color: p.hairline),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: p.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'يتم حساب أوقات الصلاة بناءً على الإحداثيات الجغرافية لمدينتك بدقة فلكية عالية دون الحاجة للاتصال الدائم بالإنترنت.',
                        style: AppTypography.meta(p.textPrimary),
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
