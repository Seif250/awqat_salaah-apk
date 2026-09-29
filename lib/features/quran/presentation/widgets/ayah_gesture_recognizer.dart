import 'dart:ui';
import 'package:flutter/gestures.dart';

/// Lightweight GestureRecognizer for Quran Ayah spans.
/// Handles both single Tap and Long-Press (holding for 380ms) with zero interference on PageView horizontal swiping.
/// Completely rejects the gesture if the pointer moves horizontally more than 8 pixels,
/// allowing PageView to swipe seamlessly.
class AyahGestureRecognizer extends LongPressGestureRecognizer {
  VoidCallback? onTap;
  bool _longPressFired = false;
  Offset? _initialPosition;

  AyahGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
  }) : super(duration: const Duration(milliseconds: 380));

  @override
  void didExceedDeadline() {
    _longPressFired = true;
    resolve(GestureDisposition.accepted);
    onLongPress?.call();
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _initialPosition = event.position;
    _longPressFired = false;
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
    } else if (event is PointerUpEvent) {
      if (!_longPressFired) {
        resolve(GestureDisposition.accepted);
        onTap?.call();
      }
      _initialPosition = null;
      _longPressFired = false;
    } else if (event is PointerCancelEvent) {
      _initialPosition = null;
      _longPressFired = false;
    }
    super.handlePrimaryPointer(event);
  }

  @override
  String get debugDescription => 'AyahGestureRecognizer';
}

