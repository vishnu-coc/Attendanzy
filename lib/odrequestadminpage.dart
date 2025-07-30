import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';

class ODRequestsAdminPage extends StatefulWidget {
  const ODRequestsAdminPage({super.key});

  @override
  State<ODRequestsAdminPage> createState() => _ODRequestsAdminPageState();
}

class _ODRequestsAdminPageState extends State<ODRequestsAdminPage> {
  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB?retryWrites=true&w=majority";
  final String collectionName = "od_requests";

  List<Map<String, dynamic>> requests = [];
  bool loading = true;
  String? error;
  String? hodDepartment;

  @override
  void initState() {
    super.initState();
    _loadHodDepartmentAndFetchRequests();
  }

  Future<void> _loadHodDepartmentAndFetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hodDepartment = prefs.getString('department');
      if (kDebugMode) {
        print("DEBUG: HOD's department loaded from session: '$hodDepartment'");
      }
    });

    if (hodDepartment != null && hodDepartment!.isNotEmpty) {
      await fetchRequests();
    } else {
      setState(() {
        loading = false;
        error = "Could not identify HOD's department. Please log in again.";
      });
    }
  }

  Future<void> fetchRequests() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final collection = db.collection(collectionName);

      // CORRECTED: Sort by 'createdAt' instead of 'date' to match your schema
      final query = mongo.where
          .eq('department', hodDepartment)
          .sortBy('createdAt', descending: true);

      if (kDebugMode) {
        print("DEBUG: Executing MongoDB query: ${query.rawFilter}");
      }
      final result = await collection.find(query).toList();

      if (kDebugMode) {
        print("DEBUG: Found ${result.length} requests for this department.");
      }

      await db.close();
      if (mounted) {
        setState(() {
          requests = List<Map<String, dynamic>>.from(result);
          loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("DEBUG: An error occurred while fetching requests: $e");
      }
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final collection = db.collection(collectionName);
      await collection.updateOne(
        mongo.where.id(mongo.ObjectId.parse(id)),
        mongo.modify.set('status', status),
      );
      await db.close();
      await fetchRequests();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request has been $status.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OD Requests'),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchRequests,
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(child: Text('Error: $error'))
                : requests.isEmpty
                ? Center(
                  child: Text('No OD requests found for your department.'),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _buildRequestCard(req);
                  },
                ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () => showDialog(
              context: context,
              builder: (context) => _buildFullScreenDialog(req),
            ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _buildCollapsedRequest(req),
        ),
      ),
    );
  }

  Widget _buildCollapsedRequest(Map<String, dynamic> req) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          req['subject'] ?? 'OD Request',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'From: ${req['from'] ?? 'N/A'}',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text('To: ${req['to'] ?? 'N/A'}', style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          'Status: ${req['status'] ?? 'pending'}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _getStatusColor(req['status']),
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenDialog(Map<String, dynamic> req) {
    final status = req['status']?.toString().toLowerCase() ?? 'pending';
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            _buildDialogHeader(status),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: _buildLetterContent(req),
              ),
            ),
            _buildActionButtons(status, req),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String status) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          const Text(
            'OD Request Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getStatusColor(status)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterContent(Map<String, dynamic> req) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("From:", req['from'] ?? 'N/A'),
          _buildDetailRow("To:", req['to'] ?? 'N/A'),

          _buildDetailRow(
            "Date Submitted:",
            req['createdAt'] != null ? req['createdAt'].split('T')[0] : 'N/A',
          ),
          const Divider(height: 30, thickness: 1),
          Text(
            req['subject'] ?? 'No Subject Provided',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            req['content'] ?? 'No content provided.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (req['image'] != null && req['image'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Proof Attached:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(base64Decode(req['image'])),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status, Map<String, dynamic> req) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept'),
              onPressed:
                  status == 'pending'
                      ? () => updateStatus(req['_id'].toHexString(), 'accepted')
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject'),
              onPressed:
                  status == 'pending'
                      ? () => updateStatus(req['_id'].toHexString(), 'rejected')
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on mongo.SelectorBuilder {
  get rawFilter => null;
}
