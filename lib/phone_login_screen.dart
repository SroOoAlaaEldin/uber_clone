import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uber_clone/otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String phoneNum = "";
  void sendCode() async {
    if (phoneNum.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال رقم الهاتف')));
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNum,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحقق: ${e.message}')));
      },
      codeSent: (String verificationId, int? resendToken) {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                OTPScreen(verificationId: verificationId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0); // يبدأ من اليمين
                  const end = Offset.zero;
                  const curve = Curves.ease;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            // type: PageTransitionType.scale,
            // alignment: Alignment.center, // أو leftToRight, fade, scale, ...
            // duration: Duration(milliseconds: 400),
            // child: OTPScreen(verificationId: verificationId),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/phone_code.png',
                  width: 150,
                  height: 150,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'أدخل رقم الهاتف لإرسال رمز التحقق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              IntlPhoneField(
                decoration: const InputDecoration(
                  hoverColor: Color.fromARGB(215, 49, 20, 5),
                  fillColor: Color.fromARGB(215, 49, 20, 5),

                  labelText: 'رقم الهاتف',
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

                initialCountryCode: 'EG', // الدولة الافتراضية (مثلاً مصر)
                onChanged: (phone) {
                  phoneNum = phone.completeNumber;
                  print(phoneNum); // للطباعة أو الاستخدام في Firebase
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: sendCode,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(215, 49, 20, 5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'إرســال كـود التحقق',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
