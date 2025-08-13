import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SearchDriver extends StatefulWidget {
  final double userLan;
  final double userLog;

  const SearchDriver({super.key, required this.userLan, required this.userLog});
  @override
  State<SearchDriver> createState() => SearchDriverState();
}

class SearchDriverState extends State<SearchDriver> {
  List<Map<String, dynamic>> driversList = [];

  @override
  void initState() {
    super.initState();
    searchDriver();
  }

  Future<void> searchDriver() async {
    // final driversnapshot = await FirebaseFirestore.instance
    //     .collection('drivers')
    //     .where('isAvailable ', isEqualTo: 'true')
    //     .get();
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('drivers')
        .get();
    List<Map<String, dynamic>> driversData = [];
    for (var doc in snapshot.docs) {
      final driver = doc.data() as Map<String, dynamic>;
      double driverlat = driver['lat'];
      double driverlog = driver['lng'];
      //حساب المسافه

      double distance = Geolocator.distanceBetween(
        widget.userLan,
        widget.userLog,
        driverlat,
        driverlog,
      );
      // بالكيلومتر

      // double price = distance * driver['pricePerKm'];

      driversData.add({
        "id": doc.id,
        "name": driver['name'],
        "carType": driver['carType'],
        "distance": distance.toStringAsFixed(2),
        "price": driver['price'],
        "lat": driver['lat'],
        "lng": driver['lng'],
      });
    }
    setState(() {
      driversList = driversData;
    });

    // هنا نعرض النتيجة في قائمة
    print(driversData);
  }

  void confirmOrder(Map<String, dynamic> driver) {
    FirebaseFirestore.instance.collection('orders').add({
      'driverId': driver['id'],
      'driverName': driver['name'],
      'price': driver['price'],
      'distance': driver['distance'],
      'userLat': widget.userLan,
      'userLng': widget.userLog,
      'isAvailable': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال الطلب إلى ${driver['name']}')),
    );
  }

  void searchDrivers() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("لايوجد سائق حاليا"));
            }
            final drivers = snapshot.data!.docs;
            return ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: Icon(Icons.directions_car, color: Colors.brown),
                  title: Text(
                    driver["name"],
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${driver["car"]}\n📍 ${driver["location"]} - 💰 ${driver["price"]} جنيه",
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    child: Text("اختيار"),
                    onPressed: () {
                      //قبل تاكيد الأختيار
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("تم اختيار ${driver["name"]}")),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("السائقين المتاحين")),
      body: driversList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: driversList.length,
              itemBuilder: (context, index) {
                var driver = driversList[index];
                return Card(
                  child: ListTile(
                    title: Text("${driver['name']} - ${driver['car']}"),
                    subtitle: Text(
                      "المسافة: ${driver['distance']} كم\nالسعر: ${driver['price']} جنيه",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => confirmOrder(driver),
                      child: Text("تأكيد"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
