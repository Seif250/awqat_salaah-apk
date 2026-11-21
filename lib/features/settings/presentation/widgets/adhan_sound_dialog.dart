import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/storage_service.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class AdhanSoundDialog {
  static String getSoundDisplayName(String soundType) {
    switch (soundType) {
      case AppConstants.soundTypeFull:
        return 'الأذان كامل';
      case AppConstants.soundTypeTakbeer:
        return 'الله أكبر الله أكبر (تكبيرات)';
      case AppConstants.soundTypeHayya:
      default:
        return 'حي على الصلاة (مختصر)';
    }
  }

  static void show(BuildContext context, String currentSoundType) {
    String selected = currentSoundType;
    String? currentlyPlaying;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final p = context.palette;
            final options = [
              {
                'key': AppConstants.soundTypeFull,
                'title': 'الأذان كامل',
                'subtitle': 'صوت الأذان كاملاً مع الترديد والدعاء',
              },
              {
                'key': AppConstants.soundTypeHayya,
                'title': 'حي على الصلاة',
                'subtitle': 'صوت الأذان المختصر المعتاد',
              },
              {
                'key': AppConstants.soundTypeTakbeer,
                'title': 'الله أكبر الله أكبر',
                'subtitle': 'تكبيرات دخول وقت الصلاة',
              },
            ];

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.music_note_rounded, color: p.accent),
                  const SizedBox(width: 8),
                  Text('اختيار صوت الأذان', style: AppTypography.sectionHeader(p.textPrimary)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'اختر صوت الأذان المفضل مع إمكانية الاستماع للتجربة قبل الاختيار:',
                      style: AppTypography.meta(p.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...options.map((opt) {
                      final key = opt['key']!;
                      final isSelected = selected == key;
                      final isPlaying = currentlyPlaying == key;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? p.primary : p.hairline,
                            width: isSelected ? 1.5 : 0.75,
                          ),
                          color: isSelected ? p.primaryContainer : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: Radio<String>(
                            value: key,
                            groupValue: selected,
                            activeColor: p.primary,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selected = val);
                              }
                            },
                          ),
                          title: Text(
                            opt['title']!,
                            style: AppTypography.rowTitle(
                              isSelected ? p.accentText : p.textPrimary,
                            ),
                          ),
                          subtitle: Text(opt['subtitle']!, style: AppTypography.label(p.textSecondary)),
                          trailing: IconButton.filledTonal(
                            tooltip: isPlaying ? 'إيقاف' : 'استماع',
                            icon: Icon(
                              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              color: isPlaying ? p.error : p.accentText,
                              size: 22,
                            ),
                            onPressed: () async {
                              if (isPlaying) {
                                await NotificationService().stopAudioPreview();
                                setDialogState(() => currentlyPlaying = null);
                              } else {
                                await NotificationService().playAudioPreview(key);
                                setDialogState(() => currentlyPlaying = key);
                              }
                            },
                          ),
                          onTap: () {
                            setDialogState(() => selected = key);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    NotificationService().stopAudioPreview();
                    Navigator.pop(dialogCtx);
                  },
                  child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
                ),
                TextButton.icon(
                  icon: Icon(Icons.notifications_active_outlined, size: 17, color: p.accentText),
                  label: Text('تجربة إشعار', style: AppTypography.meta(p.accentText)),
                  onPressed: () async {
                    await NotificationService().stopAudioPreview();
                    final res = await NotificationService().showSoundTestNotification(selected);
                    if (context.mounted) {
                      if (res == 'success') {
                        AppSnackBar.showSuccess(context, 'تم إرسال إشعار تجريبي بصوت ${getSoundDisplayName(selected)}');
                      } else {
                        AppSnackBar.showError(context, 'تعذر إرسال الإشعار: $res');
                      }
                    }
                  },
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.onPrimary),
                  onPressed: () async {
                    NotificationService().stopAudioPreview();
                    await StorageService().setNotificationSoundType(selected);
                    if (!context.mounted) return;
                    context.read<SettingsBloc>().add(ChangeNotificationSoundTypeEvent(selected));
                    context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    Navigator.pop(dialogCtx);
                    AppSnackBar.showSuccess(context, 'تم تعيين وجدولة صوت الأذان: ${getSoundDisplayName(selected)}');
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      NotificationService().stopAudioPreview();
    });
  }
}
