import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  /// Retrieve the current GPS coordinates of the user.
  /// Falls back to Kathmandu (27.7172, 85.3240) on simulator or permission denial.
  Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are active.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled. Falling back to default coordinates.');
        return _fallbackPosition();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied. Falling back.');
          return _fallbackPosition();
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied. Falling back.');
        return _fallbackPosition();
      } 

      // Try fetching last known position first for instant speed optimization
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return lastPosition;
        }
      } catch (e) {
        debugPrint('Error fetching last known position: $e');
      }

      // Fetch position with a fast 2 second maximum timeout constraint
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error fetching GPS coordinates: $e. Falling back.');
      return _fallbackPosition();
    }
  }

  Position _fallbackPosition() {
    return Position(
      latitude: 27.7172,
      longitude: 85.3240,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 1400.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}
