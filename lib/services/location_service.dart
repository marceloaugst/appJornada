import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted;
  }

  static Future<Position> getCurrentLocation() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Permissão de localização negada');
    }

    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      throw Exception('Serviço de localização desabilitado');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualizar a cada 10 metros
      ),
    );
  }
}
