import 'dart:ui';
import 'package:flutter/gestures.dart';

/// Custom GestureRecognizer for individual Ayah spans.
/// Handles both single Tap and Long-Press (holding for 500ms).
/// Naturally rejects gestures if the user swipes/scrolls to turn pages.
class AyahGestureRecognizer extends LongPressGestureRecognizer {
  VoidCallback? onTap;
  bool _longPressFired = false;

  AyahGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
  });

  @override
  void didExceedDeadline() {
    _longPressFired = true;
    resolve(GestureDisposition.accepted);
    onLongPress?.call();
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (!_longPressFired) {
        resolve(GestureDisposition.accepted);
        onTap?.call();
      }
      _longPressFired = false;
    } else if (event is PointerCancelEvent) {
      resolve(GestureDisposition.rejected);
      _longPressFired = false;
    } else if (event is PointerDownEvent) {
      _longPressFired = false;
    }
  }

  @override
  String get debugDescription => 'AyahGestureRecognizer';
}
