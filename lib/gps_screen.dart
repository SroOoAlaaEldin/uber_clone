import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:uber_clone/pick_location_screen.dart';
import 'package:uber_clone/search_driver.dart';
import 'package:uber_clone/select_car.dart';
import 'package:http/http.dart' as http;

class GpsScreen extends StatefulWidget {
  final String label;
  const GpsScreen({super.key, required this.label});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  LatLng? _currentPosition;
  String _currentAddress = "تحديد الموقع أولا";

  LatLng? _pickedCurrent;
  LatLng? _pickedDestination;
  double? currentLog;
  double? currentLat;
  Set<Marker> _markers = {};

  final TextEditingController currentLocationController =
      TextEditingController();
  final TextEditingController nextLocationController = TextEditingController();
  final TextEditingController _controller = TextEditingController();
  static const String googleMapsApiKey =
      'AIzaSyCJqFE8Kraeg8kdizejfv1rdzti2reqFvw'; // 🔴 غيّريه بمفتاحك
  bool _loading = false;
  String? selectCarType;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await _getAddAddressInArabic(position.latitude, position.longitude);
    setState(() {
      currentLat = position.latitude;
      currentLog = position.longitude;
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "موقعك الحالي"),
        ),
      );
    });
  }

  Future<void> _getAddAddressInArabic(double lat, double lng) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&language=ar&key=$googleMapsApiKey",
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data["status"] == "OK") {
      setState(() {
        _currentAddress = data["results"][0]["formatted_address"];
      });
    } else {
      setState(() {
        _currentAddress = "تعذر الحصول على العنوان";
      });
    }
  }

  Future<Map<String, dynamic>?> findNearestDriver(
    double userLat,
    double userLng,
  ) async {
    final drivers = await FirebaseFirestore.instance
        .collection('drivers')
        .where('isAvailable', isEqualTo: true)
        .get();

    double shortestDistance = double.infinity;
    Map<String, dynamic>? nearestDriver;

    for (var doc in drivers.docs) {
      final data = doc.data();
      final lat = data['location']['lat'];
      final lng = data['location']['lng'];

      final distance = await Geolocator.distanceBetween(
        userLat,
        userLng,
        lat,
        lng,
      );

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearestDriver = data;
      }
    }

    return nearestDriver;
  }

  Future<void> getLocation() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _controller.text = "رجاءً فعّل خدمة الموقع";
        setState(() => _loading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _controller.text = "تم رفض إذن الموقع";
          setState(() => _loading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _controller.text = "تم رفض الإذن نهائيًا";
        setState(() => _loading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentLat = position.latitude;
      currentLog = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      setState(() {
        _controller.text = "${place.locality}, ${place.country}";
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _controller.text = "خطأ أثناء تحديد الموقع";
        _loading = false;
      });
      print("خطأ في getLocation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تحديد الوجهة والموقع")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            SelectCar(
              onSelected: (value) {
                setState(() => selectCarType = value);
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: currentLocationController,
              readOnly: true,
              onTap: () async {
                if (selectCarType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('الرجاء اختيار نوع السيارة أولاً')),
                  );
                  return;
                }

                FocusScope.of(context).unfocus();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PickLocationScreen(label: widget.label),
                  ),
                );
                if (result != null && result is LatLng) {
                  _pickedCurrent = result;

                  List<Placemark> placemarks = await placemarkFromCoordinates(
                    _pickedCurrent!.latitude,
                    _pickedCurrent!.longitude,
                  );
                  Placemark place = placemarks.first;
                  String address = "${place.street}, ${place.locality}";

                  setState(() {
                    currentLocationController.text = address;
                  });
                }
              },
              //AIzaSyCJqFE8Kraeg8kdizejfv1rdzti2reqFvw
              decoration: InputDecoration(
                hoverColor: Color.fromARGB(215, 49, 20, 5),
                fillColor: Color.fromARGB(215, 49, 20, 5),
                suffixIcon: _pickedCurrent != null
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            // _pickedSelected = null;
                            _controller.clear();
                          });
                        },
                      )
                    : Icon(Icons.location_on),

                labelText: 'موقعك الحــالي',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.brown,
                  ), // لون الإطار العادي
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 128, 53, 30),
                    width: 2,
                  ), // لون الإطار عند التركيز
                ),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),
            TextField(
              controller: nextLocationController,
              readOnly: true,

              onTap: () async {
                if (selectCarType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('الرجاء اختيار نوع السيارة أولاً')),
                  );
                  return; //  ما يفتح الشاشة
                }
                FocusScope.of(context).unfocus();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PickLocationScreen(label: widget.label),
                  ),
                );
                if (result != null && result is LatLng) {
                  _pickedDestination = result;

                  List<Placemark> placemarks = await placemarkFromCoordinates(
                    _pickedDestination!.latitude,
                    _pickedDestination!.longitude,
                  );
                  Placemark place = placemarks.first;
                  String address = "${place.street}, ${place.locality}";

                  setState(() {
                    nextLocationController.text = address;
                  });
                }
              },
              //AIzaSyCJqFE8Kraeg8kdizejfv1rdzti2reqFvw
              decoration: InputDecoration(
                hoverColor: Color.fromARGB(215, 49, 20, 5),
                fillColor: Color.fromARGB(215, 49, 20, 5),
                suffixIcon: _pickedDestination != null
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _pickedDestination = null;
                            _controller.clear();
                          });
                        },
                      )
                    : Icon(Icons.location_on),

                labelText: 'المـوقـع الـتـالــى',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.brown,
                  ), // لون الإطار العادي
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 128, 53, 30),
                    width: 2,
                  ), // لون الإطار عند التركيز
                ),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),
            if (currentLat != null && currentLog != null)
              // استخدم الإحداثيات
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchDriver(
                        // userLan: currentLat!,
                        // userLog: currentLog!,
                        userLan: 30.05,
                        userLog: 31.24,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(215, 49, 20, 5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'الـبحـث عـن الـسائـق',
                  style: TextStyle(fontSize: 15),
                ),
              ),

            // onPressed: () async {
            //   Position position = await Geolocator.getCurrentPosition(
            //     desiredAccuracy: LocationAccuracy.high,
            //   );
            //   await searchDriver(position.latitude, position.longitude);
            // SearchDriver();
            // final currentLat =
            //     30.123; // موقع المستخدم الحالي (بدّليها بالقيم الحقيقية)
            // final currentLng = 31.456;
            // final destinationLat = 30.987; // موقع الوجهة
            // final destinationLng = 31.321;
            // final destance = await Geolocator.distanceBetween(
            //   currentLat,
            //   currentLng,
            //   destinationLat,
            //   destinationLng,
            // );
            // final nearestDriver = await findNearestDriver(
            //   currentLat,
            //   currentLng,
            // );
            // if (nearestDriver != null) {
            //   final driverName = nearestDriver['name'];
            //   // showDialog(
            //   //   context: context,
            //   //   builder: (_) => AlertDialog(
            //   //     title: Text('تـم العـثور على السـائق'),
            //   //     content: Text(
            //   //       'السائق: $driverName\nالمسافة: ${destance.toStringAsFixed(2)} كم',
            //   //     ),
            //   //   ),
            //  // );
            // } else {
            //   // showDialog(
            //   //   context: context,
            //   //   builder: (_) => AlertDialog(
            //   //     title: Text('عذرًا'),
            //   //     content: Text('لا يوجد سائق متاح الآن.'),
            //   //   ),
            //   // );
            // }
          ],
        ),
      ),
    );
  }
}
