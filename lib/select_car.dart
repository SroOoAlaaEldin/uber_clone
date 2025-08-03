import 'package:flutter/material.dart';

class SelectCar extends StatefulWidget {
  final Function(String) onSelected;

  const SelectCar({super.key, required this.onSelected});

  @override
  State<SelectCar> createState() => _SelectCarState();
}

class _SelectCarState extends State<SelectCar> {
  String selectedVehicle = 'car';

  final List<Map<String, String>> vehicles = [
    {'value': 'car', 'label': 'عربية', 'image': 'assets/images/car_one.png'},
    {
      'value': 'suv',
      'label': 'عربية كبيرة',
      'image': 'assets/images/car_two.png',
    },
    {'value': 'bike', 'label': 'موتسكل', 'image': 'assets/images/mot.png'},
    {
      'value': 'outcity',
      'label': 'خارج المدينة',
      'image': 'assets/images/car_three.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: vehicles.map((vehicle) {
            bool isSelected = selectedVehicle == vehicle['value'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      selectedVehicle = vehicle['value']!;
                    });
                    widget.onSelected(vehicle['value']!);
                  },
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.brown : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(vehicle['image']!, width: 60, height: 60),
                        SizedBox(height: 4),
                        Text(
                          vehicle['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.brown : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
