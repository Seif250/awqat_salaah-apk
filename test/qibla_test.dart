import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';

void main() {
  group('Qibla Calculation & Navigation Tests', () {
    // Holy Kaaba coordinates
    const double kaabaLat = 21.422487;
    const double kaabaLng = 39.826206;

    double calculateDistanceKm(double lat, double lng) {
      const earthRadiusKm = 6371.0;
      final dLat = (kaabaLat - lat) * (pi / 180.0);
      final dLon = (kaabaLng - lng) * (pi / 180.0);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat * (pi / 180.0)) *
              cos(kaabaLat * (pi / 180.0)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return earthRadiusKm * c;
    }

    String getDirectionCardinal(double angle) {
      if (angle >= 337.5 || angle < 22.5) return 'شمال';
      if (angle >= 22.5 && angle < 67.5) return 'شمال شرق';
      if (angle >= 67.5 && angle < 112.5) return 'شرق';
      if (angle >= 112.5 && angle < 157.5) return 'جنوب شرق';
      if (angle >= 157.5 && angle < 202.5) return 'جنوب';
      if (angle >= 202.5 && angle < 247.5) return 'جنوب غرب';
      if (angle >= 247.5 && angle < 292.5) return 'غرب';
      return 'شمال غرب';
    }

    test('Cairo Qibla angle is roughly South-East (135° - 138°)', () {
      final cairoCoords = Coordinates(30.0444, 31.2357);
      final qibla = Qibla(cairoCoords);
      final angle = qibla.direction;

      expect(angle, greaterThan(130.0));
      expect(angle, lessThan(140.0));
      expect(getDirectionCardinal(angle), 'جنوب شرق');
    });

    test('Distance from Cairo to Kaaba is roughly 1280-1300 km', () {
      final dist = calculateDistanceKm(30.0444, 31.2357);
      expect(dist, greaterThan(1250.0));
      expect(dist, lessThan(1320.0));
    });

    test('Medina Qibla angle is directly South (~177° - 180°)', () {
      final medinaCoords = Coordinates(24.4672, 39.6111);
      final qibla = Qibla(medinaCoords);
      final angle = qibla.direction;

      expect(angle, greaterThan(170.0));
      expect(angle, lessThan(185.0));
      expect(getDirectionCardinal(angle), 'جنوب');
    });

    test('Cardinal direction boundaries are accurate', () {
      expect(getDirectionCardinal(0.0), 'شمال');
      expect(getDirectionCardinal(359.0), 'شمال');
      expect(getDirectionCardinal(45.0), 'شمال شرق');
      expect(getDirectionCardinal(90.0), 'شرق');
      expect(getDirectionCardinal(135.0), 'جنوب شرق');
      expect(getDirectionCardinal(180.0), 'جنوب');
      expect(getDirectionCardinal(225.0), 'جنوب غرب');
      expect(getDirectionCardinal(270.0), 'غرب');
      expect(getDirectionCardinal(315.0), 'شمال غرب');
    });

    test('Shortest circular angle delta calculates properly across 360/0 boundary', () {
      double computeDelta(double target, double current) {
        double diff = target - (current % 360.0);
        while (diff < -180.0) {
          diff += 360.0;
        }
        while (diff > 180.0) {
          diff -= 360.0;
        }
        return diff;
      }

      // Turning right from 355° to 5° -> diff is +10°
      expect(computeDelta(5.0, 355.0), 10.0);

      // Turning left from 5° to 355° -> diff is -10°
      expect(computeDelta(355.0, 5.0), -10.0);

      // Normal delta from 90° to 120° -> diff is +30°
      expect(computeDelta(120.0, 90.0), 30.0);

      // Normal delta from 120° to 90° -> diff is -30°
      expect(computeDelta(90.0, 120.0), -30.0);
    });
  });
}
