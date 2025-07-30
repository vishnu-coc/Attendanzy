import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ODRequestPage extends StatefulWidget {
  const ODRequestPage({super.key});

  @override
  State<ODRequestPage> createState() => _ODRequestPageState();
}

class _ODRequestPageState extends State<ODRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fromAddressController = TextEditingController();
  final TextEditingController toAddressController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  File? _proofImage;
  // Place this inside your _ODRequestPageState class

  /// Fetches the logged-in student's email and department from SharedPreferences.
  Future<Map<String, String>> _getStudentSessionDetails() async {
    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString('email') ?? '';
    final department = prefs.getString('department') ?? '';

    // Return a map containing both values
    return {'email': email, 'department': department};
  }

  String? requestStatus; // "pending", "accepted", "rejected"
  bool expanded = false;
  Map<String, dynamic>? savedRequestData;

  // MongoDB config
  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB?retryWrites=true&w=majority";
  final String collectionName = "od_requests";

  // Use this as your user identifier (replace with actual user id/email in production)
  String get userIdentifier => fromAddressController.text.trim();

  @override
  void initState() {
    super.initState();
    _loadRequestStatus();
  }

  Future<void> _loadRequestStatus() async {
    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final collection = db.collection(collectionName);

      // Always fetch the latest request for the user from MongoDB
      // Replace 'from' with your actual user field if needed
      final latestList =
          await collection
              .find(
                mongo.where
                    .eq('from', userIdentifier)
                    .sortBy('createdAt', descending: true),
              )
              .toList();

      await db.close();

      if (latestList.isNotEmpty) {
        final mongoReq = latestList.first;
        setState(() {
          requestStatus = mongoReq['status'] ?? "pending";
          savedRequestData = mongoReq;
          fromAddressController.text = mongoReq['from'] ?? '';
          toAddressController.text = mongoReq['to'] ?? '';
          subjectController.text = mongoReq['subject'] ?? '';
          contentController.text = mongoReq['content'] ?? '';
        });
        // Save this as the latest request locally
        await _saveRequestToPrefs(mongoReq);
        return;
      }
    } catch (e) {
      print("Error fetching latest OD request: $e");
    }

    // If nothing found, clear state
    setState(() {
      requestStatus = null;
      savedRequestData = null;
      fromAddressController.clear();
      toAddressController.clear();
      subjectController.clear();
      contentController.clear();
    });
  }

  Future<void> _saveRequestToPrefs(Map<String, dynamic> requestData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('od_request', jsonEncode(requestData));
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _proofImage = File(picked.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    final sessionDetails = await _getStudentSessionDetails();

    // 2. Extract the email and department from the result
    final studentEmail = sessionDetails['email'];
    final studentDepartment = sessionDetails['department'];
    if (_formKey.currentState!.validate()) {
      String? imageBase64;
      if (_proofImage != null) {
        final bytes = await _proofImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final requestData = {
        "studentEmail": studentEmail,
        "from": fromAddressController.text.trim(),
        "to": toAddressController.text.trim(),
        "subject": subjectController.text.trim(),
        "content": contentController.text.trim(),
        "image": imageBase64 ?? "",
        "createdAt": DateTime.now().toIso8601String(),
        "department": studentDepartment,
        "status": "pending",
      };

      try {
        final db = await mongo.Db.create(mongoUri);
        await db.open();
        final collection = db.collection(collectionName);

        final mongoData = Map<String, dynamic>.from(requestData);
        mongoData.updateAll(
          (key, value) => value is String ? value : value?.toString() ?? "",
        );

        final result = await collection.insertOne(mongoData);

        await db.close();

        if (!result.isSuccess) {
          throw Exception("Insert failed: ${result.errmsg}");
        }

        // Save to SharedPreferences only after successful DB insert
        await _saveRequestToPrefs(requestData);

        // Always reload from DB to get the latest status
        await _loadRequestStatus();

        setState(() {
          expanded = false;
        });

        // Show the success dialog with request details
        _showRequestSubmittedDialog(requestData);
        // Show the custom dialog with request details
        _showRequestSubmittedDialog(requestData);
      } catch (e, st) {
        print("MongoDB error: $e\n$st");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit request: $e')));
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'On Duty Request',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                ),
                pw.SizedBox(height: 16),
                pw.Text('To,\n${data["to"] ?? ""}'),
                pw.SizedBox(height: 16),
                pw.Text('From,\n${data["from"] ?? ""}'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Subject: ${data["subject"] ?? ""}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Respected Sir/Madam,'),
                pw.SizedBox(height: 8),
                pw.Text(data["content"] ?? ""),
                pw.SizedBox(height: 16),
                pw.Text('Thank you.'),
                pw.SizedBox(height: 32),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Signature: _______________'),
                ),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _refreshStatus() async {
    await _loadRequestStatus();
    // If accepted, show the accepted card and not the form or letter view
    if (requestStatus == "accepted") {
      setState(() {
        expanded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your OD request has been accepted!')),
      );
    } else if (requestStatus == "rejected") {
      setState(() {
        expanded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your OD request has been rejected.')),
      );
    }
  }

  void _showRequestSubmittedDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Request Submitted Successfully',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('From:', data['from'] ?? ''),
                        const SizedBox(height: 12),
                        _buildDetailRow('To:', data['to'] ?? ''),
                        const SizedBox(height: 12),
                        _buildDetailRow('Subject:', data['subject'] ?? ''),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Status:',
                          'Pending Review',
                          isStatus: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Content:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['content'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                expanded = true;
                              });
                            },
                            child: const Text(
                              'View Full Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isStatus ? Colors.orange[700] : const Color(0xFF2C3E50),
              fontWeight: isStatus ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If request is accepted, always show the accepted card with download, never the form or letter view
    if (savedRequestData != null && savedRequestData!['status'] == 'accepted') {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text('On Duty Request'),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF222B45)),
          titleTextStyle: const TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Check Status",
              onPressed: _refreshStatus,
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
              child: _buildLetterCard(
                theme,
                forceAccepted: true,
                disableTap: true,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('On Duty Request'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF222B45)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF222B45),
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
        actions: [
          if (savedRequestData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Check Status",
              onPressed: _refreshStatus,
            ),
        ],
      ),
      body:
          savedRequestData != null
              ? Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 32,
                    ),
                    child:
                        expanded
                            ? _buildProfessionalLetter(theme, savedRequestData!)
                            : _buildLetterCard(theme),
                  ),
                ),
              )
              : Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 32,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.blue.shade50.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.9),
                            blurRadius: 24,
                            offset: const Offset(0, -8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Hero(
                                  tag: 'od_icon',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.blue.shade700,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.shade300
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: const Icon(
                                      Icons.event_available_rounded,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: Text(
                                  "Request On Duty",
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF222B45),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  "Fill the details below to request OD from your HOD.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 15.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _modernTextField(
                                controller: fromAddressController,
                                label: 'From Address',
                                icon: Icons.home,
                                validator:
                                    (v) =>
                                        v!.isEmpty
                                            ? 'Enter your address'
                                            : null,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              _modernTextField(
                                controller: toAddressController,
                                label: 'To Address',
                                icon: Icons.location_on,
                                validator:
                                    (v) =>
                                        v!.isEmpty
                                            ? 'Enter recipient address'
                                            : null,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              _modernTextField(
                                controller: subjectController,
                                label: 'Subject',
                                icon: Icons.subject,
                                validator:
                                    (v) => v!.isEmpty ? 'Enter subject' : null,
                              ),
                              const SizedBox(height: 16),
                              _modernTextField(
                                controller: contentController,
                                label: 'Reason/Content',
                                icon: Icons.edit_note,
                                maxLines: 3,
                                validator:
                                    (v) =>
                                        v!.isEmpty ? 'Enter your reason' : null,
                              ),
                              const SizedBox(height: 22),
                              Text(
                                "Upload Proof (Optional)",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _proofImage == null
                                  ? OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.upload_file,
                                      color: Color(0xFF1A73E8),
                                    ),
                                    label: const Text('Choose File'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF1A73E8),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _pickImage,
                                  )
                                  : Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _proofImage!,
                                          height: 120,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed:
                                            () => setState(
                                              () => _proofImage = null,
                                            ),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Remove',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    elevation: 0,
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                  ).copyWith(
                                    elevation:
                                        MaterialStateProperty.resolveWith<
                                          double
                                        >((Set<MaterialState> states) {
                                          if (states.contains(
                                            MaterialState.pressed,
                                          )) {
                                            return 0;
                                          }
                                          return 8;
                                        }),
                                  ),
                                  onPressed: _submitRequest,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.send, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        'Submit Request',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildLetterCard(
    ThemeData theme, {
    bool forceAccepted = false,
    bool disableTap = false,
  }) {
    final data =
        savedRequestData ??
        {
          "from": fromAddressController.text,
          "to": toAddressController.text,
          "subject": subjectController.text,
          "content": contentController.text,
          "image": "",
          "createdAt": DateTime.now().toIso8601String(),
          "status": requestStatus ?? "pending",
        };

    final isAccepted = forceAccepted || data["status"] == "accepted";

    return GestureDetector(
      onTap:
          disableTap
              ? null
              : () {
                if (isAccepted) {
                  setState(() => expanded = true);
                }
              },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "OD Request",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
                fontSize: 22,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "To: ${data["to"] ?? ""}",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.blueGrey[900],
                fontSize: 16.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "From: ${data["from"] ?? ""}",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.blueGrey[900],
                fontSize: 16.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Subject: ${data["subject"] ?? ""}",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.blueGrey[900],
                fontSize: 16.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data["content"] ?? "",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.blueGrey[900],
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  data["status"] == "pending"
                      ? Icons.hourglass_top
                      : data["status"] == "accepted"
                      ? Icons.check_circle
                      : Icons.cancel,
                  color:
                      data["status"] == "pending"
                          ? Colors.orange[700]
                          : data["status"] == "accepted"
                          ? Colors.green[700]
                          : Colors.red[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Status: ${data["status"] ?? "pending"}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                if (isAccepted) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: () => _downloadPdf(data),
                  ),
                ],
              ],
            ),
            if (isAccepted)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  "Your OD request has been accepted. Download your letter below.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalLetter(ThemeData theme, Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title at top left, close at top right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "OD Request",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 22,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                  tooltip: "Back",
                  onPressed: () => setState(() => expanded = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "To,\n${data["to"] ?? ""}",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[900],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "From,\n${data["from"] ?? ""}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.blueGrey[900],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Subject: ${data["subject"] ?? ""}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
                fontSize: 16.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Respected Sir/Madam,",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data["content"] ?? "",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Thank you.",
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15.5),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Signature: _______________",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.grey.shade300, thickness: 1.1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  data["status"] == "pending"
                      ? Icons.hourglass_top
                      : data["status"] == "accepted"
                      ? Icons.check_circle
                      : Icons.cancel,
                  color:
                      data["status"] == "pending"
                          ? Colors.orange[700]
                          : data["status"] == "accepted"
                          ? Colors.green[700]
                          : Colors.red[700],
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  data["status"] == "accepted"
                      ? "Status: Accepted"
                      : data["status"] == "rejected"
                      ? "Status: Rejected"
                      : "Status: Waiting for verification",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        data["status"] == "accepted"
                            ? Colors.green[800]
                            : data["status"] == "rejected"
                            ? Colors.red[800]
                            : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (data["status"] == "accepted") ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: () => _downloadPdf(data),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: Colors.blue.shade100.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
