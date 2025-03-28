import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sisthub/staff_availability_page.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SisthubApp());
}

class SisthubApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sisthub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/staffAvailability': (context) => StaffAvailabilityPage(),
      },
    );
  }
}