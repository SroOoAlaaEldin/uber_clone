import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/pick_location_screen.dart';
import 'package:uber_clone/select_car.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class GpsScreen extends StatefulWidget {
  final String label;
  const GpsScreen({super.key, required this.label});
  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  LatLng? _nextPicked;

  LatLng? _currentPicked;

  Set<Polyline> _polyline = {};
  List<LatLng> _polylineCorr = [];
  final TextEditingController currentLocationController =
      TextEditingController();
  final TextEditingController nextLocationController = TextEditingController();
  Future<void> _getPolyline(LatLng start, LatLng end) async {
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey:
          'AIzaSyCJqFE8Kraeg8kdizejfv1rdzti2reqFvw', // ← تأكد من مفتاحك الصحيح
    );

    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: RoutesApiRequest(
        // ← ✅ استخدم التحديث الجديد هنا
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        travelMode:
            TravelMode.driving, // مطلوب الآن واسم المتغير تغير من transitMode
      ),
    );

    if (result.points.isNotEmpty) {
      _polylineCorr.clear();
      for (var point in result.points) {
        _polylineCorr.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polyline = {
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.brown,
            width: 5,
            points: _polylineCorr,
          ),
        };
      });
    } else {
      print("❌ لا يوجد نقاط في المسار");
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

  final PageController controller = PageController();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController crrunetController = TextEditingController();
  bool _loading = false;
  int currentPage = 0;
  String? nextPage;
  String no_loaction = " يجب تحديد الموقع ";
  String buttonText = "أعــرف موقعك";
  LatLng? _pickedSelected;
  String? selectCarType;

  Future<void> getLocation() async {
    setState(() => _loading = true);

    try {
      // التحقق من تفعيل الخدمة
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _controller.text = "رجاءً فعّل خدمة الموقع";
        setState(() => _loading = false);
        return;
      }

      // التحقق من الأذونات
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

      // جلب الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // تحويل الإحداثيات إلى اسم مدينة
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

  String? selectedVehicle;
  late Timer autoScroller;
  final List<Widget> pages = [
    Container(
      color: Colors.red,
      child: Center(
        child: Text(
          "التطبيق الأول والأخيــر",
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    ),
    Container(
      color: const Color.fromARGB(255, 143, 124, 3),
      child: Center(
        child: Text(
          "التطبيق الأول والأخيــر",
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    ),
    Container(
      color: const Color.fromARGB(255, 46, 14, 135),
      child: Center(
        child: Text(
          "نـرحب بيكم في تطبيق وصلني",
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    ),
    Container(
      color: const Color.fromARGB(255, 67, 255, 89),
      child: Center(
        child: Text(
          "التطبيق الأول والأخيــر",
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    ),
    Container(
      color: Colors.red,
      child: Center(
        child: Text(
          "نـرحب بيكم في تطبيق وصلني",
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    ),
  ];
  @override
  void initState() {
    super.initState();
    autoScroller = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (currentPage < pages.length - 1) {
        currentPage++;
      } else {
        currentPage = 0;
      }
      controller.animateToPage(
        currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    autoScroller.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PageView(controller: controller, children: pages),

                  // SizedBox(height: 1), // ظ…ط³ط§ظپط© ط¨ط³ظٹط·ط©
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0.1),
                      child: ElevatedButton(
                        onPressed: getLocation,
                        child: Text(buttonText),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.black.withOpacity(0.7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 3),
            SelectCar(
              onSelected: (value) {
                setState(() => selectCarType = value);
              },
            ),
            SizedBox(height: 20),
            //      if (selectCarType!= null) ...[],
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    controller: currentLocationController,
                    readOnly: true,
                    onTap: () async {
                      if (selectCarType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('الرجاء اختيار نوع السيارة أولاً'),
                          ),
                        );
                        return; // 🛑 ما يفتح الشاشة
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
                        _pickedSelected = result;

                        // احضار العنوان
                        List<Placemark> placemarks =
                            await placemarkFromCoordinates(
                              _pickedSelected!.latitude,
                              _pickedSelected!.longitude,
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
                      suffixIcon: _pickedSelected != null
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _pickedSelected = null;
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
                          SnackBar(
                            content: Text('الرجاء اختيار نوع السيارة أولاً'),
                          ),
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
                        _pickedSelected = result;

                        // احضار العنوان
                        List<Placemark> placemarks =
                            await placemarkFromCoordinates(
                              _pickedSelected!.latitude,
                              _pickedSelected!.longitude,
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
                      suffixIcon: _pickedSelected != null
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _pickedSelected = null;
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
                  ElevatedButton(
                    onPressed: () async {
                      final currentLat =
                          30.123; // موقع المستخدم الحالي (بدّليها بالقيم الحقيقية)
                      final currentLng = 31.456;
                      final destinationLat = 30.987; // موقع الوجهة
                      final destinationLng = 31.321;
                      final destance = await Geolocator.distanceBetween(
                        currentLat,
                        currentLng,
                        destinationLat,
                        destinationLng,
                      );
                      final nearestDriver = await findNearestDriver(
                        currentLat,
                        currentLng,
                      );
                      if (nearestDriver != null) {
                        final driverName = nearestDriver['name'];
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('تـم العـثور على السـائق'),
                            content: Text(
                              'السائق: $driverName\nالمسافة: ${destance.toStringAsFixed(2)} كم',
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('عذرًا'),
                            content: Text('لا يوجد سائق متاح الآن.'),
                          ),
                        );
                      }
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
