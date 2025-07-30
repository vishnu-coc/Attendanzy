import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceSelectionPage extends StatefulWidget {
  const AttendanceSelectionPage({super.key});
  @override
  State<AttendanceSelectionPage> createState() =>
      _AttendanceSelectionPageState();
}

class _AttendanceSelectionPageState extends State<AttendanceSelectionPage> {
  String? _department; // Fetched from SharedPreferences
  String? _selectedYear;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _getDepartment();
  }

  Future<void> _getDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _department = prefs.getString('department') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 40),
                      // === >> DELETE DEPARTMENT DROPDOWN << ===
                      // Instead, just small info row:
                      if (_department != null && _department!.isNotEmpty) ...[
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Department: $_department',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      // Year Dropdown
                      CustomDropdown(
                        hintText: 'Year',
                        items: const [
                          '1st Year',
                          '2nd Year',
                          '3rd Year',
                          '4th Year',
                        ],
                        value: _selectedYear,
                        onChanged: (value) {
                          setState(() => _selectedYear = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      // Section Dropdown
                      CustomDropdown(
                        hintText: 'Section',
                        items: const ['A', 'B', 'C', 'NULL'],
                        value: _selectedSection,
                        onChanged: (value) {
                          setState(() => _selectedSection = value);
                        },
                      ),
                      const Spacer(),
                      _buildNextButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Select Attendance Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return ElevatedButton(
      onPressed:
          (_department != null &&
                  _department!.isNotEmpty &&
                  _selectedYear != null &&
                  _selectedSection != null)
              ? () {
                Navigator.pushNamed(
                  context,
                  '/attendancemark',
                  arguments: {
                    'department': _department,
                    'year': _selectedYear,
                    'section': _selectedSection,
                  },
                );
              }
              : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 5,
      ),
      child: const Text(
        'Next',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String hintText;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    super.key,
    required this.hintText,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(border: InputBorder.none),
          hint: Text(hintText, style: const TextStyle(color: Colors.grey)),
          items:
              items
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
