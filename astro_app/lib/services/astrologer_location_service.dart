import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'astro_api_service.dart';

class AstrologerLocation {
  final String city;
  final double latitude;
  final double longitude;
  final double timezone;

  const AstrologerLocation({
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  Map<String, dynamic> toMap() => {
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
  };
}

class AstrologerLocationService {
  static const String _keyCity = 'astrologer_default_city';
  static const String _keyLat = 'astrologer_default_lat';
  static const String _keyLon = 'astrologer_default_lon';
  static const String _keyTz = 'astrologer_default_tz';

  /// ValueNotifier to broadcast location updates across all active screens in real-time
  static final ValueNotifier<AstrologerLocation?> locationNotifier = ValueNotifier(null);

  /// Fetch the current saved Astrologer location.
  /// If none has been set yet, queries the backend geocoding service for the first default location.
  static Future<AstrologerLocation> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString(_keyCity);
    final savedLat = prefs.getDouble(_keyLat);
    final savedLon = prefs.getDouble(_keyLon);
    final savedTz = prefs.getDouble(_keyTz);

    if (savedCity != null && savedLat != null && savedLon != null && savedTz != null) {
      final loc = AstrologerLocation(
        city: savedCity,
        latitude: savedLat,
        longitude: savedLon,
        timezone: savedTz,
      );
      locationNotifier.value = loc;
      return loc;
    }

    // If not set yet, fetch place dynamically from the backend geocoding service
    try {
      final places = await AstroApiService.getPlaces();
      if (places.isNotEmpty) {
        final p = places.first;
        final lat = double.tryParse(p['lat_val'] ?? '') ?? 28.6139;
        final lon = double.tryParse(p['lon_val'] ?? '') ?? 77.2090;
        final tz = double.tryParse(p['tz_val'] ?? '') ?? 5.5;
        final city = p['city'] ?? 'New Delhi, India';

        final loc = AstrologerLocation(
          city: city,
          latitude: lat,
          longitude: lon,
          timezone: tz,
        );
        await setLocation(loc);
        return loc;
      }
    } catch (e) {
      debugPrint('AstrologerLocationService backend geocoding fallback: $e');
    }

    const fallback = AstrologerLocation(
      city: 'New Delhi, India',
      latitude: 28.6139,
      longitude: 77.2090,
      timezone: 5.5,
    );
    locationNotifier.value = fallback;
    return fallback;
  }

  /// Persist the astrologer's chosen location (e.g. Bijapur, Mumbai, etc.)
  static Future<void> setLocation(AstrologerLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCity, location.city);
    await prefs.setDouble(_keyLat, location.latitude);
    await prefs.setDouble(_keyLon, location.longitude);
    await prefs.setDouble(_keyTz, location.timezone);
    locationNotifier.value = location;
  }
}
