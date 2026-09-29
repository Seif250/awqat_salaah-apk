/// Display mode for the Medina Mushaf reader.
enum QuranDisplayMode {
  /// Standard QCF V2 monochrome Medina Mushaf layout.
  normal,

  /// QCF Tajweed V4 color-coded Medina Mushaf layout using official page-specific COLRv1 fonts.
  tajweed;

  String get displayNameArabic {
    switch (this) {
      case QuranDisplayMode.normal:
        return 'المصحف العادي';
      case QuranDisplayMode.tajweed:
        return 'مصحف التجويد الملون';
    }
  }

  bool get isTajweed => this == QuranDisplayMode.tajweed;
}
