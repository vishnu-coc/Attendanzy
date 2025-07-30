import 'package:flutter/material.dart';
import 'package:flutter_attendence_app/odRequestDetailPage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class StudentODStatusPage extends StatefulWidget {
  final String studentEmail;

  const StudentODStatusPage({super.key, required this.studentEmail});

  @override
  State<StudentODStatusPage> createState() => _StudentODStatusPageState();
}

class _StudentODStatusPageState extends State<StudentODStatusPage> {
  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB?retryWrites=true&w=majority";
  final String collectionName = "od_requests";

  List<Map<String, dynamic>> myRequests = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStudentRequests();
  }

  Future<void> fetchStudentRequests() async {
    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final collection = db.collection(collectionName);
      final result =
          await collection
              .find(mongo.where.eq("studentEmail", widget.studentEmail))
              .toList();
      await db.close();

      setState(() {
        myRequests = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My OD Requests"),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text("Error: $error"))
              : myRequests.isEmpty
              ? const Center(child: Text("No OD requests submitted."))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myRequests.length,
                itemBuilder: (context, index) {
                  final req = myRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        req['subject'] ?? 'OD Request',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('From: ${req['from'] ?? ''}'),
                          Text('To: ${req['to'] ?? ''}'),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${req['status'] ?? 'pending'}',
                            style: TextStyle(
                              color:
                                  req['status'] == 'accepted'
                                      ? Colors.green
                                      : req['status'] == 'rejected'
                                      ? Colors.red
                                      : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ODRequestDetailPage(requestData: req),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
