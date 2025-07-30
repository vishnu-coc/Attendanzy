import 'package:flutter/material.dart';
import 'package:flutter_attendence_app/AnimatedHeader.dart';
import 'package:flutter_attendence_app/odrequestadminpage.dart';
import 'package:flutter_attendence_app/odrequestpage.dart';
import 'package:flutter_attendence_app/studentODstatespage.dart';
import 'profile_page.dart';

import 'help_page.dart';
import 'absentees_page.dart';

import 'package:url_launcher/url_launcher.dart';
import 'services/feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String email;
  final Map<String, dynamic> profile;
  final bool isStaff;
  final String role; // 'user', 'staff', 'hod'

  const HomePage({
    super.key,
    required this.name,
    required this.email,
    required this.profile,
    required this.isStaff,
    required this.role,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _feedbackText = "";
  int _rating = 0;

  bool get isUser => widget.role.toLowerCase() == 'user';
  bool get isStaff => widget.role.toLowerCase() == 'staff';
  bool get isHod => widget.role.toLowerCase() == 'hod';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isUser
                ? "Student Dashboard"
                : isStaff
                ? "Staff Dashboard"
                : "Hod Dashboard",
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              onSelected: (choice) async {
                if (choice == "profile") {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => ProfilePage(
                            name: widget.name,
                            email: widget.email,
                          ),
                    ),
                  );
                } else if (choice == "change_password") {
                  Navigator.of(context).pushNamed('/changepassword');
                } else if (choice == 'help') {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const HelpPage()));
                } else if (choice == "feedback") {
                  _showFeedbackDialog();
                } else if (choice == "about") {
                  AboutDialog();
                } else if (choice == "logout") {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              itemBuilder:
                  (_) => [
                    const PopupMenuItem(
                      value: "profile",
                      child: Text("Profile"),
                    ),
                    const PopupMenuItem(
                      value: "change_password",
                      child: Text("Change Password"),
                    ),
                    const PopupMenuItem(value: "help", child: Text("Help")),
                    const PopupMenuItem(
                      value: "feedback",
                      child: Text("Send Feedback"),
                    ),
                    const PopupMenuItem(value: "about", child: Text("About")),
                    const PopupMenuItem(value: "logout", child: Text("Logout")),
                  ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AnimatedHeader(name: widget.name),
              Row(
                children: [
                  Expanded(
                    child: categoryCard(
                      title: isStaff || isHod ? "Mark Attendance" : "Absentees",
                      icon:
                          isStaff || isHod ? Icons.check_circle : Icons.people,
                      onTap: () {
                        if (isStaff || isHod) {
                          Navigator.of(context).pushNamed('/attendancepage');
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AbsenteesPage()),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: categoryCard(
                      title: 'Profile',
                      icon: Icons.person,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => ProfilePage(
                                  name: widget.name,
                                  email: widget.email,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: categoryCard(
                      title: 'Result',
                      icon: Icons.school,
                      onTap: () async {
                        const url = 'http://www.coe.act.edu.in/students';
                        if (await canLaunch(url)) {
                          await launch(url);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: categoryCard(
                      title: 'Timetable',
                      icon: Icons.schedule,
                      onTap: () {
                        Navigator.of(context).pushNamed('/timetablepage');
                      },
                    ),
                  ),
                ],
              ),
              if (isUser) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: categoryCard(
                        title: "CGPA Calculator",
                        icon: Icons.calculate,
                        onTap: () {
                          Navigator.of(context).pushNamed("/cgpaCalculator");
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: categoryCard(
                        title: "GPA Calculator",
                        icon: Icons.calculate_outlined,
                        onTap: () {
                          Navigator.of(context).pushNamed("/gpaCalculator");
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: categoryCard(
                        title: "OD",
                        icon: Icons.event_available,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ODRequestPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: categoryCard(
                        title: "OD Requests",
                        icon: Icons.note,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => StudentODStatusPage(
                                    studentEmail: widget.email,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (isHod) ...[
                const SizedBox(height: 20),
                categoryCard(
                  title: "OD",
                  icon: Icons.event_available,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ODRequestsAdminPage(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpPage()));
          },
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Send Feedback"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Write your feedback here",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _feedbackText = val),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_feedbackText.trim().isEmpty || _rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please provide feedback and rating"),
                    ),
                  );
                  return;
                }
                bool success = await FeedbackService.submitFeedback(
                  widget.email,
                  _feedbackText,
                  _rating,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Thank you for your feedback"
                          : "Failed to submit feedback",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}

Widget categoryCard({
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
