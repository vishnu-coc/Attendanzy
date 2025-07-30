import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB";
  final String timetableCollection = "timetable";

  List<dynamic>? selectedDayTimetable;
  bool isLoading = true;
  String? today;
  String? selectedDay;

  @override
  void initState() {
    super.initState();
    today = getTodayName();
    loadSelectedDay(); // Load the last selected day or default to today
  }

  Future<void> loadSelectedDay() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDay = prefs.getString('selectedDay');
    if (savedDay != null) {
      setState(() {
        selectedDay = savedDay;
      });
      print("🔍 Loaded saved day: $savedDay");
    } else {
      setState(() {
        selectedDay = today; // Default to today
      });
      print("🔍 No saved day found. Defaulting to today: $today");
    }
    fetchTimetableForSelectedDay(); // Fetch timetable for the selected day
  }

  Future<void> saveSelectedDay(String day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedDay', day); // Save the selected day
    print("✅ Saved selected day: $day");
  }

  Future<void> fetchTimetableForSelectedDay() async {
    try {
      setState(() {
        isLoading = true; // Show loading animation
      });

      var db = await mongo.Db.create(mongoUri);
      await db.open();
      print("✅ Connected to MongoDB");

      var collection = db.collection(timetableCollection);

      print("🔍 Fetching timetable for: $selectedDay");

      var result = await collection.findOne({
        "department": "Department of Computer Science and Engineering",
        "year": "3rd Year",
        "section": "B",
        "semester": "Even Semester 2024-2025",
      });

      if (result != null) {
        print("🔍 Timetable Data: ${result["time_table"]}"); // Debugging log
        if (result["time_table"] != null &&
            result["time_table"][selectedDay] != null) {
          setState(() {
            selectedDayTimetable = result["time_table"][selectedDay];
          });
          print("✅ Timetable fetched successfully for $selectedDay.");
        } else {
          print("⚠️ Timetable data not found for $selectedDay.");
          setState(() {
            selectedDayTimetable = [];
          });
        }
      } else {
        print("⚠️ Timetable data not found in the database.");
        setState(() {
          selectedDayTimetable = [];
        });
      }

      await db.close();
    } catch (e) {
      print("⚠️ Error fetching timetable data: $e");
    } finally {
      setState(() {
        isLoading = false; // Hide loading animation
      });
    }
  }

  String getTodayName() {
    List<String> days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    final weekday = DateTime.now().weekday;
    return days[weekday - 1]; // Correctly map weekday to day name
  }

  void showDaySelectionDialog() {
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          titlePadding: EdgeInsets.zero, // Remove default padding
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Text(
              "Select a Day",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          content: SizedBox(
            height: 400, // Set a fixed height for the dialog content
            width: double.maxFinite, // Ensure the dialog takes full width
            child: ListView.separated(
              itemCount: days.length,
              separatorBuilder: (context, index) => const Divider(height: 25),
              itemBuilder: (context, index) {
                final day = days[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  tileColor: const Color.fromARGB(255, 68, 138, 255),
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Color.fromARGB(255, 251, 251, 252),
                  ),
                  title: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(221, 254, 254, 255),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the dialog
                    setState(() {
                      selectedDay = day; // Update the selected day
                    });
                    saveSelectedDay(day); // Save the selected day
                    fetchTimetableForSelectedDay(); // Fetch timetable for the selected day
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildLoadingAnimation() {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.blueAccent,
        size: 50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timetable"),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          // Show the edit button only if today is Saturday
          if (getTodayName() == "Saturday")
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: showDaySelectionDialog,
            ),
        ],
      ),
      body:
          isLoading
              ? buildLoadingAnimation()
              : RefreshIndicator(
                onRefresh: fetchTimetableForSelectedDay, // Pull-to-refresh
                child:
                    selectedDayTimetable == null ||
                            selectedDayTimetable!.isEmpty
                        ? const Center(
                          child: Text(
                            "No timetable data available for the selected day.",
                            style: TextStyle(fontSize: 20, color: Colors.grey),
                          ),
                        )
                        : ListView(
                          children: [
                            Container(
                              width: double.infinity,
                              color: Colors.blueAccent,
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                "$selectedDay's Timetable", // Display the selected day
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            ...selectedDayTimetable!.map((period) {
                              return buildPeriodCard(period);
                            }),
                          ],
                        ),
              ),
    );
  }

  Widget buildPeriodCard(Map<String, dynamic> period) {
    final isCompleted = isPeriodCompleted(period['time']);
    final cardColor = isCompleted ? Colors.green[50] : Colors.blue[50];
    final iconColor = isCompleted ? Colors.green : Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.schedule,
                  color: iconColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Period: ${period['period']}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Time: ${period['time']}",
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.book, color: Colors.orangeAccent, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Subject: ${period['subject']}",
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.purpleAccent, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${period['staff_name']}",
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool isPeriodCompleted(String time) {
    try {
      final normalizedTime = time.replaceAll('.', ':');
      final times = normalizedTime.split("-");
      final endTime = times[1].trim();

      final now = TimeOfDay.now();
      final end = parseTimeOfDay(endTime);

      return now.hour > end.hour ||
          (now.hour == end.hour && now.minute >= end.minute);
    } catch (e) {
      print("⚠️ Error parsing time: $time, Error: $e");
      return false;
    }
  }

  TimeOfDay parseTimeOfDay(String time) {
    final match = RegExp(r'(\d+):(\d+)(am|pm)').firstMatch(time.toLowerCase());
    if (match == null) {
      throw FormatException("Invalid time format: $time");
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;

    final isPM = period == 'pm';
    final normalizedHour =
        (isPM && hour != 12) ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);

    return TimeOfDay(hour: normalizedHour, minute: minute);
  }
}
