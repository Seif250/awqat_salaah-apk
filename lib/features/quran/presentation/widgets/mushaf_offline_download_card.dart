import 'package:flutter/material.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/quran_display_mode.dart';
import '../../services/qcf_font_service.dart';

/// Reader-settings card that downloads the Tajweed page fonts of all 604
/// pages once, so the Mushaf can be read without internet.
class MushafOfflineDownloadCard extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Color accentColor;

  const MushafOfflineDownloadCard({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  State<MushafOfflineDownloadCard> createState() =>
      _MushafOfflineDownloadCardState();
}

class _MushafOfflineDownloadCardState extends State<MushafOfflineDownloadCard> {
  final _service = QcfFontService.instance;
  int? _downloaded;
  int _lastFailed = 0;

  @override
  void initState() {
    super.initState();
    _service.offlineDownload.addListener(_onProgress);
    _refreshCount();
  }

  @override
  void dispose() {
    _service.offlineDownload.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshCount() async {
    final count =
        await _service.countDownloadedFonts(mode: QuranDisplayMode.tajweed);
    if (mounted) setState(() => _downloaded = count);
  }

  Future<void> _start() async {
    setState(() => _lastFailed = 0);
    final result = await _service.startOfflineDownload();
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _downloaded = result.done;
        _lastFailed = result.failed;
      });
    } else {
      _refreshCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    const total = QcfFontService.totalPages;
    final running = _service.offlineDownload.value;
    final done = running?.done ?? _downloaded;
    final isComplete = done != null && done >= total;

    final String subtitle;
    if (done == null) {
      subtitle = 'جاري الفحص…';
    } else if (running != null) {
      subtitle =
          'جاري التحميل: ${toArabicDigits(done)} من ${toArabicDigits(total)} صفحة';
    } else if (isComplete) {
      subtitle = 'المصحف كامل على الجهاز ويعمل بدون إنترنت';
    } else if (_lastFailed > 0) {
      subtitle =
          'تعذر تحميل ${toArabicDigits(_lastFailed)} صفحة. تأكد من الاتصال ثم أكمل التحميل';
    } else {
      subtitle =
          '${toArabicDigits(done)} من ${toArabicDigits(total)} صفحة محمّلة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.borderColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isComplete
                      ? Icons.offline_pin_rounded
                      : Icons.download_for_offline_outlined,
                  size: 20,
                  color: widget.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المصحف بدون إنترنت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: widget.textColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (running != null)
                TextButton(
                  onPressed: _service.cancelOfflineDownload,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.accentColor,
                  ),
                  child: const Text(
                    'إيقاف',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                )
              else if (done != null && !isComplete)
                TextButton(
                  onPressed: _start,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.accentColor,
                  ),
                  child: Text(
                    done == 0 ? 'تحميل' : 'إكمال',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (running != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: running.done / total,
              color: widget.accentColor,
              backgroundColor: widget.accentColor.withValues(alpha: 0.15),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
    );
  }
}
