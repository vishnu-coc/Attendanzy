import 'package:flutter/material.dart';

class CgpaCalculatorPage extends StatefulWidget {
  const CgpaCalculatorPage({super.key});

  @override
  State<CgpaCalculatorPage> createState() => _CgpaCalculatorPageState();
}

class _CgpaCalculatorPageState extends State<CgpaCalculatorPage> {
  final TextEditingController _semesterController = TextEditingController();
  final List<TextEditingController> _gpaControllers = [];
  double _cgpa = 0.0;
  bool _showSemesterInput = true;

  void _generateInputFields() {
    int numberOfSemesters = int.tryParse(_semesterController.text) ?? 0;

    if (numberOfSemesters > 0) {
      setState(() {
        _gpaControllers.clear();
        for (int i = 0; i < numberOfSemesters; i++) {
          _gpaControllers.add(TextEditingController());
        }
        _showSemesterInput = false; // Hide semester input box
      });
    }
  }

  void _calculateCgpa() {
    // Check if all GPA fields are filled
    for (var controller in _gpaControllers) {
      if (controller.text.isEmpty) {
        // Clear any existing SnackBars before showing a new one
        ScaffoldMessenger.of(context).clearSnackBars();

        // Enhanced SnackBar for missing GPA fields
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please fill in all GPA fields to calculate CGPA.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color.fromARGB(255, 66, 97, 238),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            duration: const Duration(seconds: 1), // Shorter duration
          ),
        );
        return; // Stop calculation if any field is empty
      }
    }

    double totalGpa = 0.0;

    for (var controller in _gpaControllers) {
      double gpa = double.tryParse(controller.text) ?? 0.0;
      totalGpa += gpa;
    }

    setState(() {
      _cgpa =
          _gpaControllers.isNotEmpty ? totalGpa / _gpaControllers.length : 0.0;
    });

    // Show CGPA in a custom-styled popup dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Center(
              child: Text(
                '🎓 CGPA Result',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Your CGPA is:',
                  style: TextStyle(fontSize: 20, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Text(
                  _cgpa.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _cgpa >= 7.5 ? Colors.green : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _cgpa >= 7.5
                      ? '🌟 Excellent work! Keep striving for greatness!'
                      : '💪 Don’t give up! Work harder and aim for the stars!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: _cgpa >= 7.5 ? Colors.green : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Remember, consistency is the key to success!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
        backgroundColor: const Color(0xFF1565C0), // Blue color
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0), // Blue
              Colors.white, // White in the middle
            ],
            stops: [0.3, 0.3], // Blue occupies the top 30%
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header with Description
              const Text(
                'CGPA Calculator',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Calculate your CGPA by entering the number of semesters and the GPA for each semester. '
                'This tool helps you track your academic performance effectively.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),

              // Input for number of semesters (only visible initially)
              if (_showSemesterInput)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _semesterController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter number of semesters',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.school, color: Color(0xFF1565C0)),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              if (_showSemesterInput) const SizedBox(height: 10),
              if (_showSemesterInput)
                Center(
                  child: ElevatedButton(
                    onPressed: _generateInputFields,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Generate Input Fields',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // White text for better contrast
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // GPA input fields for each semester
              if (!_showSemesterInput)
                Expanded(
                  child: ListView.builder(
                    itemCount: _gpaControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _gpaControllers[index],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'GPA for Semester ${index + 1}',
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.grade,
                                color: Color(0xFF1565C0),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Calculate CGPA button
              if (!_showSemesterInput)
                Center(
                  child: ElevatedButton(
                    onPressed: _calculateCgpa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Calculate CGPA',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // White text for better contrast
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
