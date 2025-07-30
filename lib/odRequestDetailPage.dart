import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:async';

class ODRequestDetailPage extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const ODRequestDetailPage({super.key, required this.requestData});

  @override
  ODRequestDetailPageState createState() => ODRequestDetailPageState();
}

class ODRequestDetailPageState extends State<ODRequestDetailPage> {
  bool isExpanded = false;
  Timer? _midnightTimer;
  late final Map<String, dynamic> _requestData;

  @override
  void initState() {
    super.initState();
    _initializeRequestData();
    _scheduleMidnightUpdate();
  }

  void _initializeRequestData() {
    String sanitizeValue(dynamic value) {
      if (value == null) return '';
      final str = value.toString().trim();
      return str.isEmpty ? '' : str;
    }

    // Create a new map with proper data validation
    _requestData = {
      'from': sanitizeValue(widget.requestData['from']),
      'to': sanitizeValue(widget.requestData['to']),
      'date': sanitizeValue(widget.requestData['date']),
      'time': sanitizeValue(widget.requestData['time']),
      'reason': sanitizeValue(widget.requestData['reason']),
      'content': sanitizeValue(widget.requestData['content']),
      'subject': sanitizeValue(widget.requestData['subject']),
      'department': sanitizeValue(widget.requestData['department']),
      'status': sanitizeValue(widget.requestData['status']).toLowerCase(),
      'timestamp': sanitizeValue(widget.requestData['timestamp']),
    };
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      // Check if the request is accepted/rejected and older than today
      final requestDate = DateTime.parse(
        widget.requestData['timestamp'].toString(),
      );
      final status = widget.requestData['status']?.toString().toLowerCase();

      if ((status == 'accepted' || status == 'rejected') &&
          requestDate.isBefore(DateTime(now.year, now.month, now.day))) {
        if (mounted) {
          Navigator.of(context).pop(); // Close the detail page
        }
      }

      // Schedule the next update
      _scheduleMidnightUpdate();
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to extract student name from 'from' address
  String _extractStudentName(String? fromAddress) {
    if (fromAddress == null || fromAddress.isEmpty) return '';
    // Assuming the name is the first line or before the first comma
    final parts = fromAddress.split('\n').first.split(',');
    return parts[0].trim();
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final pdf = pw.Document();

    // Load the HOD signature image if request is accepted
    pw.Image? hodSignature;
    if (_requestData['status'].toString().toLowerCase() == 'accepted') {
      try {
        final signatureImage = await rootBundle.load('assets/image/sign.jpg');
        final signatureBytes = signatureImage.buffer.asUint8List();
        hodSignature = pw.Image(
          pw.MemoryImage(signatureBytes),
          width: 150,
          height: 50,
        );
      } catch (e) {
        print('Error loading HOD signature: $e');
      }
    }

    // Define styles for the letter
    const double margin = 40.0;
    const double contentMargin = 40.0;
    const double lineSpacing = 16.0;

    // Define text styles
    final headerStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final subheaderStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );
    final bodyStyle = const pw.TextStyle(fontSize: 12, lineSpacing: 1.5);
    final labelStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(margin),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Letter head with decorative line
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('ON-DUTY REQUEST LETTER', style: headerStyle),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      width: 200,
                      height: 1,
                      margin: const pw.EdgeInsets.symmetric(vertical: 8),
                      color: PdfColor.fromInt(0xFF757575),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: lineSpacing * 2),

              // Date within content margin
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: contentMargin,
                ),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Date: ${_requestData['date'] ?? DateTime.now().toString().split(' ')[0]}',
                  style: bodyStyle,
                ),
              ),
              pw.SizedBox(height: lineSpacing * 2),

              // From section with better formatting
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: contentMargin,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('From:', style: labelStyle),
                    pw.SizedBox(height: 4),
                    pw.Text(_requestData['from'] ?? '', style: bodyStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: lineSpacing),

              // To section
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: contentMargin,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('To:', style: labelStyle),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _requestData['to'] ??
                          'The Head of the Department,\nComputer Science and Engineering,\nNational Institute of Technology,\nTiruchirappalli - 620015',
                      style: bodyStyle,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: lineSpacing),

              // Subject with emphasis
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: contentMargin,
                  vertical: 8,
                ),
                child: pw.Text(
                  'Subject: ${_requestData['subject'] ?? 'Request for On-Duty Permission'}',
                  style: subheaderStyle,
                ),
              ),
              pw.SizedBox(height: lineSpacing),

              // Salutation
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: contentMargin,
                ),
                child: pw.Text('Respected Sir/Madam,', style: bodyStyle),
              ),
              pw.SizedBox(height: lineSpacing),

              // Body Content with proper margins and text alignment
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: contentMargin,
                ),
                child: pw.Text(
                  _requestData['content'] ?? '',
                  style: bodyStyle,
                  textAlign: pw.TextAlign.justify,
                ),
              ),
              pw.SizedBox(height: lineSpacing),

              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: contentMargin,
                  ),
                  child: pw.Text('Thank you.', style: bodyStyle),
                ),
              ),
              pw.SizedBox(height: lineSpacing * 3),

              // Signature spaces with better formatting
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: contentMargin,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left side: Course Instructor and HOD signatures
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Teacher Signature (first)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 150,
                              height: 50,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                    width: 0.5,
                                    color: PdfColor.fromInt(0xFFBDBDBD),
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text('Course Instructor', style: labelStyle),
                          ],
                        ),
                        pw.SizedBox(height: 30),
                        // HOD Signature (second)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (hodSignature != null)
                              hodSignature
                            else
                              pw.Container(
                                width: 150,
                                height: 50,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      width: 0.5,
                                      color: PdfColor.fromInt(0xFFBDBDBD),
                                    ),
                                  ),
                                ),
                              ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Head of the Department',
                              style: labelStyle,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Computer Science and Engineering',
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Student name and closing on right
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Yours sincerely,', style: bodyStyle),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          _extractStudentName(_requestData['from']),
                          style: labelStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Use printing package to download the PDF
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'OD_Request_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAccepted =
        _requestData['status'].toString().toLowerCase() == 'accepted';
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: size.width,
            maxHeight: size.height,
          ),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              // Header with back button, title and status
              Container(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 50,
                  bottom: 12,
                ),
                decoration: const BoxDecoration(color: Colors.white),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    const Text(
                      'OD Request Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          _requestData['status'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(_requestData['status']),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _requestData['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(_requestData['status']),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Letter content in scrollable area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'ON-DUTY REQUEST LETTER',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Divider(thickness: 1),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Date: ${_requestData['date'] ?? 'Not Specified'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // From section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _requestData['from'] ?? 'Not Specified',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // To section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _requestData['to'] ?? 'Not Specified',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Subject
                        Text(
                          'Subject: ${_requestData['subject'] ?? 'Request for On-Duty Permission'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Letter content
                        const Text(
                          'Respected Sir/Madam,',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _requestData['content'] ?? 'No content provided',
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 20),

                        // Thank you
                        const Center(
                          child: Text(
                            'Thank you for your consideration.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Download button for accepted requests
              if (isAccepted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Download OD Request Letter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _downloadPdf(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
