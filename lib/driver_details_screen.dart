import 'package:flutter/material.dart';

class DriverDetailsScreen extends StatelessWidget {
  final String name;
  final String car;
  final double rating;
  final double distance;
  const DriverDetailsScreen({
    super.key,
    required this.name,
    required this.car,
    required this.rating,
    required this.distance,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("🚗 اسم السائق: $name", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text("🚘 السيارة: $car", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("⭐ التقييم: $rating", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              "📍 يبعد عنك: ${distance.toStringAsFixed(1)} كم",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // استدعاء إرسال الطلب
              },
              icon: Icon(Icons.check_circle),
              label: Text("تأكيد الطلب"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
