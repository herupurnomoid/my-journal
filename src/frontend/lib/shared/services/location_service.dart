import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Requests permission and returns a formatted location string
  /// e.g. "Kemang, Jakarta Selatan" or null if failed/denied.
  Future<String?> getCurrentAccurateLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // 2. Cek izin akses lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      // 3. Dapatkan koordinat saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Lakukan reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';
        
        if (subLocality.isNotEmpty && locality.isNotEmpty) {
          return '$subLocality, $locality';
        } else if (locality.isNotEmpty) {
          return locality;
        } else if (place.administrativeArea != null) {
          return place.administrativeArea;
        }
      }
      return 'Lokasi Tidak Diketahui';
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}
