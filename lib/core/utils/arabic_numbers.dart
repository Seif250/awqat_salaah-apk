/// Helper functions for converting Western digits to Arabic-Indic digits.
String toArabicDigits(dynamic value) {
  final str = value.toString();
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  var result = str;
  for (var i = 0; i < western.length; i++) {
    result = result.replaceAll(western[i], eastern[i]);
  }
  return result;
}

/// Formats an ayah number with traditional Quranic ornament brackets.
String formatAyahEnd(int ayahNumber) {
  return ' ﴿${toArabicDigits(ayahNumber)}﴾ ';
}
