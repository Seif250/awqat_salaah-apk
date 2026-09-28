import 'package:flutter/gestures.dart';

/// Lightweight GestureRecognizer for Quran Ayah spans.
/// Handles Long-Press (holding for 400ms) with zero interference on PageView horizontal swiping.
/// Completely rejects the gesture if the pointer moves horizontally more than 10 pixels,
/// allowing PageView to swipe seamlessly.
class AyahGestureRecognizer extends LongPressGestureRecognizer {
  AyahGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
  }) : super(duration: const Duration(milliseconds: 380));

  Offset? _initialPosition;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _initialPosition = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerMoveEvent && _initialPosition != null) {
      final deltaX = (event.position.dx - _initialPosition!.dx).abs();
      final deltaY = (event.position.dy - _initialPosition!.dy).abs();
      // If horizontal movement exceeds 8 pixels, user is turning pages: release immediately!
      if (deltaX > 8.0 || deltaY > 18.0) {
        resolve(GestureDisposition.rejected);
        return;
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _initialPosition = null;
    }
    super.handlePrimaryPointer(event);
  }

  @override
  String get debugDescription => 'AyahGestureRecognizer';
}
