import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_attendence_app/attendancedetails.dart';
import 'package:flutter_attendence_app/cgpa_calculator.dart';
import 'package:flutter_attendence_app/changepassword.dart';
import 'package:flutter_attendence_app/firebase_api.dart';
import 'package:flutter_attendence_app/firebase_options.dart';
import 'package:flutter_attendence_app/gpa_calculator.dart';
import 'package:flutter_attendence_app/help_page.dart';
import 'package:flutter_attendence_app/homepage.dart';
import 'package:flutter_attendence_app/attendance.dart';
import 'package:flutter_attendence_app/loginpage.dart';
import 'package:flutter_attendence_app/odrequestpage.dart';
import 'package:flutter_attendence_app/profile_page.dart';
import 'package:flutter_attendence_app/timetable_page.dart';
import 'package:flutter_attendence_app/attendancemark.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  ); // Preserve the splash screen
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  await FirebaseApi().initNotifications(); // Initialize Firebase Messaging

  // Retrieve the user's role from SharedPreferences
  final isStaff = await getUserRole();

  runApp(MyApp(isStaff: isStaff));
}

Future<bool> getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isStaff') ?? false; // Default to false (student)
}

class MyApp extends StatefulWidget {
  final bool isStaff;

  const MyApp({super.key, required this.isStaff});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    // Reduced delay to improve performance
    await Future.delayed(const Duration(seconds: 1));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/loginpage', // Changed initial route to login page
      routes: {
        '/loginpage': (context) => const LoginPage(),
        '/homepage':
            (context) => HomePage(
              name: 'Default Name',
              email: 'default@example.com',
              profile: {'key': 'Default Profile'},
              isStaff: widget.isStaff,
              role: 'user',
            ),
        '/attendancepage': (context) => const AttendanceSelectionPage(),
        '/attendancemark': (context) => const AttendanceScreen(),
        '/attendancedetails':
            (context) => AttendanceDetailsScreen(
              department: 'Default Department',
              year: 'Default Year',
              section: 'Default Section',
              presentStudents: [],
              absentStudents: [],
              onDutyStudents: [],
              onEdit: (Map<String, bool> updatedAttendance) {
                print(updatedAttendance);
              },
            ),
        '/cgpaCalculator': (context) => const CgpaCalculatorPage(),
        '/profilepage':
            (context) => const ProfilePage(
              name: 'Default Name',
              email: 'default@example.com',
            ),
        '/gpaCalculator': (context) => const GPACalculatorPage(),
        '/help': (context) => const HelpPage(),
        '/timetablepage': (context) => TimetablePage(),
        '/odrequestpage': (context) => const ODRequestPage(),
      },
    );
  }
}
