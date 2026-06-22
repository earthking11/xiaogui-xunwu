import 'package:geocoding/geocoding.dart';

typedef PlacemarkReader =
    Future<List<Placemark>> Function(double latitude, double longitude);

class ReadableLocationService {
  ReadableLocationService({PlacemarkReader? placemarkReader})
    : _placemarkReader = placemarkReader ?? placemarkFromCoordinates;

  final PlacemarkReader _placemarkReader;

  Future<String?> resolve({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await _placemarkReader(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5));
      if (placemarks.isEmpty) return null;
      return _format(placemarks.first);
    } on Exception {
      return null;
    }
  }

  String? _format(Placemark placemark) {
    final parts = <String>{};
    for (final value in [
      placemark.administrativeArea,
      placemark.subAdministrativeArea,
      placemark.locality,
      placemark.subLocality,
      placemark.thoroughfare,
      placemark.name,
    ]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        parts.add(trimmed);
      }
    }
    if (parts.isEmpty) return null;
    return parts.join('');
  }
}
