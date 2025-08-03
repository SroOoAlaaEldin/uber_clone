import 'package:geolocator/geolocator.dart';

class DriverService {
  Future<double> calculatestance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
