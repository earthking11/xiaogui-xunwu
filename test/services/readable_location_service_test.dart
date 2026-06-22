import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:xiaogui_xunwu/services/readable_location_service.dart';

void main() {
  test('formats a readable location from a placemark', () async {
    final service = ReadableLocationService(
      placemarkReader: (_, _) async => [
        Placemark(
          administrativeArea: '福建省',
          locality: '福州市',
          subLocality: '仓山区',
          thoroughfare: '金山大道',
          name: '金山大道',
        ),
      ],
    );

    final location = await service.resolve(latitude: 26.01, longitude: 119.3);

    expect(location, '福建省福州市仓山区金山大道');
  });

  test(
    'returns null when reverse geocoding cannot resolve a location',
    () async {
      final service = ReadableLocationService(
        placemarkReader: (_, _) async => const [],
      );

      final location = await service.resolve(latitude: 26.01, longitude: 119.3);

      expect(location, isNull);
    },
  );
}
