import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'attendancedetails.dart'; // Assuming this is the attendance details page.

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  Map<String, dynamic> attendance =
      {}; // true (Present), false (Absent), null (OD)
  bool isLoading = true;
  String searchQuery = "";

  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB";
  final String studentCollection = "students";

  String? department;
  String? year;
  String? section;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    department = arguments['department'];
    year = arguments['year'];
    section = arguments['section'];

    fetchStudents(department, year, section);
  }

  Future<void> fetchStudents(
    String? department,
    String? year,
    String? section,
  ) async {
    setState(() => isLoading = true);
    try {
      var db = await mongo.Db.create(mongoUri);
      await db.open();
      var collection = db.collection(studentCollection);

      // Fetching the entire document that matches department, year, and section
      var studentList = await collection.findOne({
        "dep": department,
        "year": year,
        "sec": section,
      });

      if (studentList != null && studentList['students'] != null) {
        setState(() {
          // Extract the students array
          students = List<Map<String, dynamic>>.from(studentList['students']);
          attendance = {
            for (var student in students) student["register_no"]: true,
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No students found for the selected parameters!"),
          ),
        );
      }
      await db.close();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load students: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void submitAttendance() async {
    List<Map<String, dynamic>> absentees =
        students.where((s) => attendance[s["register_no"]] == false).toList();
    List<Map<String, dynamic>> presents =
        students.where((s) => attendance[s["register_no"]] == true).toList();
    List<Map<String, dynamic>> onDuty =
        students.where((s) => attendance[s["register_no"]] == null).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AttendanceDetailsScreen(
              presentStudents: presents,
              absentStudents: absentees,
              onDutyStudents: onDuty,
              department: department ?? '',
              year: year ?? '',
              section: section ?? '',
              onEdit: (updatedAttendance) {
                setState(() {
                  attendance = updatedAttendance;
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mark Attendance"),
        backgroundColor: Colors.blueAccent,
      ),
      body:
          isLoading
              ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blueAccent,
                  size: 50,
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Student List",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Search Bar
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Search Student",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Using a 'for' loop to display all students
                            for (var student in students)
                              if (searchQuery.isEmpty ||
                                  student['name'].toLowerCase().contains(
                                    searchQuery.toLowerCase(),
                                  ))
                                Card(
                                  elevation: 4,
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Colors.blueAccent,
                                          child: Text(
                                            student['name'][0]
                                                .toUpperCase(), // First letter of name
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student['name'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Register No: ${student['register_no']}",
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildRadioOption(
                                              "P",
                                              true,
                                              student["register_no"],
                                            ),
                                            _buildRadioOption(
                                              "A",
                                              false,
                                              student["register_no"],
                                            ),
                                            _buildRadioOption(
                                              "OD",
                                              null,
                                              student["register_no"],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Submit Attendance"),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildRadioOption(String label, dynamic value, String registerNo) {
    return Row(
      children: [
        Radio<dynamic>(
          value: value,
          groupValue: attendance[registerNo],
          onChanged: (newValue) {
            setState(() {
              attendance[registerNo] = newValue;
            });
          },
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
