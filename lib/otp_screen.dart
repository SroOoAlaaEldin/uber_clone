import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;

  const OTPScreen({super.key, required this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpContoller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void verifyCode() async {
    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: otpContoller.text.trim(),
    );

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      // دخّل المستخدم على الصفحة الرئيسية
      Navigator.pushReplacementNamed(context, '/gps');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('رمز التحقق غير صحيح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("أدخل كود التحقق")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/phone_verifcation.png',
                  width: 150,
                  height: 150,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'أدخــل كـود التحقق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: otpContoller,
                autoFocus: true,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 50,
                  activeColor: Colors.brown,
                  selectedColor: Colors.brown.shade700,
                  inactiveColor: Colors.grey.shade300,
                ),
                onChanged: (value) {},
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: verifyCode,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(215, 49, 20, 5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: const Text('تأكــيد', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
