import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AbsenteesPage extends StatefulWidget {
  const AbsenteesPage({super.key});

  @override
  State<AbsenteesPage> createState() => _AbsenteesPageState();
}

class _AbsenteesPageState extends State<AbsenteesPage> {
  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB";
  final String collectionName = "absentees";
  String? department, year, section;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  Map<String, List<Map<String, dynamic>>> groupedAbsentees = {};

  @override
  void initState() {
    super.initState();
    _loadContextAndAbsentees();
  }

  Future<void> _loadContextAndAbsentees() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      department = prefs.getString('department');
      year = prefs.getString('year');
      section = prefs.getString('section');
    });
    await fetchAbsentees();
  }

  Future<void> fetchAbsentees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final coll = db.collection(collectionName);

      final start = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final end = start.add(const Duration(days: 1));

      // Query for this student's department, year, section and selected date.
      final data = await coll.findOne({
        "date": {
          r"$gte": start.toIso8601String(),
          r"$lt": end.toIso8601String(),
        },
        "department": department,
        "year": year,
        "section": section,
      });

      Map<String, List<Map<String, dynamic>>> grouped = {};
      if (data != null && data['absentees'] != null) {
        List<Map<String, dynamic>> absentees = List<Map<String, dynamic>>.from(
          data['absentees'],
        );
        for (var absentee in absentees) {
          String firstLetter = (absentee['name'] ?? 'Unknown')[0].toUpperCase();
          grouped.putIfAbsent(firstLetter, () => []).add(absentee);
        }
      }

      setState(() {
        groupedAbsentees = grouped;
      });

      await db.close();
    } catch (_) {
      setState(() => groupedAbsentees = {});
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      fetchAbsentees();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedLetters = List.generate(26, (i) => String.fromCharCode(65 + i));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Class Absentees',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Show fixed class info at top instead of dropdowns
          Card(
            color: const Color(0xFFE3F2FD),
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Dept: $department   Year: $year   Section: $section',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.blue,
                        size: 50,
                      ),
                    )
                    : groupedAbsentees.isEmpty
                    ? const Center(
                      child: Text(
                        "No absentees found for your class on this date.",
                      ),
                    )
                    : ListView(
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      children:
                          sortedLetters
                              .where(
                                (letter) =>
                                    groupedAbsentees.containsKey(letter),
                              )
                              .map((letter) {
                                final absentees = groupedAbsentees[letter]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        letter,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...absentees.map((absentee) {
                                      final name =
                                          absentee['name'] ?? 'Unknown';
                                      return ListTile(
                                        leading: CircleAvatar(
                                          child: Text(name[0].toUpperCase()),
                                        ),
                                        title: Text(name),
                                      );
                                    }),
                                  ],
                                );
                              })
                              .toList(),
                    ),
          ),
        ],
      ),
    );
  }
}
