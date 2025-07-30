import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:url_launcher/url_launcher.dart';

class AttendanceDetailsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> presentStudents;
  final List<Map<String, dynamic>> absentStudents;
  final List<Map<String, dynamic>> onDutyStudents;
  final Function(Map<String, bool>) onEdit;
  final String department;
  final String year;
  final String section;

  const AttendanceDetailsScreen({
    super.key,
    required this.presentStudents,
    required this.absentStudents,
    required this.onDutyStudents,
    required this.onEdit,
    required this.department,
    required this.year,
    required this.section,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AttendanceDetailsScreenState createState() =>
      _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB";
  final String studentCollection = "students";
  final String absenteesCollection = "absentees";

  String? classInChargeNumber; // Store the incharge_no
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData(); // Initialize data asynchronously
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await fetchClassInChargeNumber(); // Fetch the incharge number
    setState(() {
      isLoading = false; // Stop loading once data is fetched
    });
  }

  Future<void> fetchClassInChargeNumber() async {
    try {
      // Connect to MongoDB
      var db = await mongo.Db.create(mongoUri);
      await db.open();
      print("✅ Connected to MongoDB");

      // Get the collection
      var collection = db.collection(studentCollection);

      // Query the database for the incharge_no based on department, year, and section
      var result = await collection.findOne({
        "dep": widget.department,
        "year": widget.year,
        "sec": widget.section,
      });

      if (result != null && result.containsKey("incharge_no")) {
        setState(() {
          classInChargeNumber = result["incharge_no"];
        });
        print("✅ Incharge number fetched: $classInChargeNumber");
      } else {
        print(
          "⚠ Incharge number not found for department: ${widget.department}, year: ${widget.year}, section: ${widget.section}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Incharge number not found for the selected department, year, and section.",
            ),
          ),
        );
      }

      await db.close();
    } catch (e) {
      print("⚠ Error fetching incharge number: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching incharge number: $e")),
      );
    }
  }

  Future<void> saveAttendanceToDatabase(BuildContext context) async {
    try {
      // Connect to MongoDB
      var db = await mongo.Db.create(mongoUri);
      await db.open();
      print("✅ Connected to MongoDB");

      // Get the absentees collection
      var collection = db.collection(absenteesCollection);

      // Prepare the data to insert
      var dataToInsert = {
        "date": DateTime.now().toIso8601String(),
        "department": widget.department,
        "year": widget.year,
        "section": widget.section,
        "total_present": widget.presentStudents.length,
        "total_absent": widget.absentStudents.length,
        "total_on_duty": widget.onDutyStudents.length,
        "present_students":
            widget.presentStudents.map((student) {
              return {
                "name": student['name'],
                "register_no": student['register_no'],
              };
            }).toList(),
        "absentees":
            widget.absentStudents.map((student) {
              return {
                "name": student['name'],
                "register_no": student['register_no'],
              };
            }).toList(),
        "on_duty":
            widget.onDutyStudents.map((student) {
              return {
                "name": student['name'],
                "register_no": student['register_no'],
              };
            }).toList(),
      };

      print("📤 Data to insert: $dataToInsert");

      // Insert the data
      var result = await collection.insertOne(dataToInsert);

      // Log the result of the insertion
      print("📥 Insert result: ${result.isSuccess ? 'Success' : 'Failure'}");

      await db.close();

      if (result.isSuccess) {
        print("✅ Attendance successfully stored in the database!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Attendance successfully stored in the database!"),
          ),
        );
      } else {
        print("❌ Failed to store attendance in the database!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to store attendance in the database!"),
          ),
        );
      }
    } catch (e) {
      print("⚠ Error saving attendance to database: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving attendance: $e")));
    }
  }

  void shareAttendanceList(BuildContext context) async {
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please wait, fetching incharge number...")),
      );
      return;
    }

    if (widget.absentStudents.isEmpty && widget.onDutyStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No absentees or on-duty students to share.")),
      );
      return;
    }

    if (classInChargeNumber == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Incharge number not available.")));
      return;
    }

    // Save attendance to the database before sharing
    await saveAttendanceToDatabase(context);

    String formattedDate =
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";

    // Prepare the message
    String message = " Attendance Report for $formattedDate \n\n";
    message += " Total Students Present: ${widget.presentStudents.length}\n";
    message += " Total Students Absent: ${widget.absentStudents.length}\n";
    message += " Total Students On Duty: ${widget.onDutyStudents.length}\n\n";

    if (widget.absentStudents.isNotEmpty) {
      message += " Absentees List:\n";
      for (int i = 0; i < widget.absentStudents.length; i++) {
        message +=
            "${i + 1}. ${widget.absentStudents[i]['name']} (Reg: ${widget.absentStudents[i]['register_no']})\n";
      }
    }

    if (widget.onDutyStudents.isNotEmpty) {
      message += "\n On Duty List:\n";
      for (int i = 0; i < widget.onDutyStudents.length; i++) {
        message +=
            "${i + 1}. ${widget.onDutyStudents[i]['name']} (Reg: ${widget.onDutyStudents[i]['register_no']})\n";
      }
    }

    String encodedMessage = Uri.encodeComponent(message);
    String whatsappUrl =
        "https://wa.me/$classInChargeNumber?text=$encodedMessage";

    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠ WhatsApp is not installed!")));
    }
  }

  Widget buildStudentList(
    List<Map<String, dynamic>> students,
    String emptyMessage,
  ) {
    if (students.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        var student = students[index];
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 20,
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              student['name'],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Reg No: ${student['register_no']}",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Details"),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: "Absent"), Tab(text: "On Duty")],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading spinner
              : TabBarView(
                controller: _tabController,
                children: [
                  buildStudentList(
                    widget.absentStudents,
                    "No absentees to display.",
                  ),
                  buildStudentList(
                    widget.onDutyStudents,
                    "No students on duty to display.",
                  ),
                ],
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.edit, size: 18, color: Colors.white),
                label: Text(
                  "Edit Attendance",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => shareAttendanceList(context),
                icon: Icon(Icons.send, size: 18, color: Colors.white),
                label: Text(
                  "Send to WhatsApp",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
