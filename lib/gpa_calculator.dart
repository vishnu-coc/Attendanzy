import 'package:flutter/material.dart';

class GPACalculatorPage extends StatefulWidget {
  const GPACalculatorPage({super.key});
  @override
  _GPACalculatorPageState createState() => _GPACalculatorPageState();
}

class _GPACalculatorPageState extends State<GPACalculatorPage> {
  final semesterController = TextEditingController();
  final subjectCountController = TextEditingController();

  List<TextEditingController> subjectCodeControllers = [];
  List<TextEditingController> creditControllers = [];
  List<String> selectedGrades = [];

  bool showInitialInput = true;
  int subjectCount = 0;
  double? gpa;

  String? selectedRegulation; // Regulation selection
  final List<String> regulationOptions = ['R2021'];

  final Map<String, double> gradeMap = {
    'O': 10,
    'A+': 9,
    'A': 8,
    'B+': 7,
    'B': 6,
    'C': 5,
  };

  final List<String> gradeOptions = ['O', 'A+', 'A', 'B+', 'B', 'C'];

  @override
  void dispose() {
    semesterController.dispose();
    subjectCountController.dispose();
    for (var controller in subjectCodeControllers) {
      controller.dispose();
    }
    for (var controller in creditControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void generateInputFields() {
    // Validate Regulation, Semester, and Number of Subjects
    if (selectedRegulation == null ||
        semesterController.text.isEmpty ||
        subjectCountController.text.isEmpty) {
      // Clear any existing SnackBars before showing a new one
      ScaffoldMessenger.of(context).clearSnackBars();

      // Show SnackBar alert for missing input fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please fill in Regulation, Semester, and Number of Subjects.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 21, 101, 192),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          duration: const Duration(seconds: 2), // Shorter duration
        ),
      );
      return; // Stop if any field is empty
    }

    subjectCount = int.tryParse(subjectCountController.text) ?? 0;
    subjectCodeControllers = List.generate(
      subjectCount,
      (_) => TextEditingController(),
    );
    creditControllers = List.generate(
      subjectCount,
      (_) => TextEditingController(),
    );
    selectedGrades = List.generate(subjectCount, (_) => 'O');

    setState(() {
      showInitialInput = false;
    });
  }

  void calculateGPA() {
    // Check if all input fields are filled
    for (int i = 0; i < subjectCount; i++) {
      if (subjectCodeControllers[i].text.isEmpty ||
          creditControllers[i].text.isEmpty) {
        // Clear any existing SnackBars before showing a new one
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show SnackBar alert for missing input fields
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please fill in all fields to calculate GPA.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color.fromARGB(255, 21, 101, 192),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            duration: const Duration(seconds: 2), // Shorter duration
          ),
        );
        return; // Stop calculation if any field is empty
      }
    }

    double totalCredits = 0;
    double totalGradePoints = 0;

    for (int i = 0; i < subjectCount; i++) {
      double credit = double.tryParse(creditControllers[i].text) ?? 0;
      double gradePoint = gradeMap[selectedGrades[i]] ?? 0;

      totalCredits += credit;
      totalGradePoints += credit * gradePoint;
    }

    setState(() {
      gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0;
    });

    // Show GPA in a custom-styled popup dialog
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
                '🎓 GPA Result',
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
                  'Your GPA is:',
                  style: TextStyle(fontSize: 20, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Text(
                  gpa!.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: gpa! >= 7.5 ? Colors.green : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  gpa! >= 7.5
                      ? '🌟 Excellent work! Keep striving for greatness!'
                      : '💪 Don’t give up! Work harder and aim for the stars!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: gpa! >= 7.5 ? Colors.green : Colors.redAccent,
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
                    backgroundColor: Color.fromARGB(255, 21, 101, 192),
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

  Widget buildInitialInputUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 21, 101, 192),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.school, size: 80, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'GPA Calculator',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Enter your semester and subject details below',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Input Fields Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Regulation Selection Dropdown
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: DropdownButtonFormField<String>(
                          value: selectedRegulation,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.rule,
                              color: Colors.blueAccent,
                            ),
                            labelText: 'Select Regulation',
                            labelStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                          items:
                              regulationOptions
                                  .map(
                                    (regulation) => DropdownMenuItem(
                                      value: regulation,
                                      child: Text(regulation),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRegulation = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    buildInputCard(
                      'Semester',
                      semesterController,
                      Icons.calendar_today,
                    ),
                    SizedBox(height: 16),
                    buildInputCard(
                      'Number of Subjects',
                      subjectCountController,
                      Icons.format_list_numbered,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: generateInputFields,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 30,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: Text(
                        'Generate Input Fields',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputCard(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueAccent),
            labelText: label,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            hintText: "Enter $label",
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSubjectForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter Subject Details",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 20),
          ...List.generate(subjectCount, (index) {
            return Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Subject Code Input
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: subjectCodeControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Code',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          hintText: "Code",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Credit Hours Input
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: creditControllers[index],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Credits',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          hintText: "Credits",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Grade Dropdown
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: selectedGrades[index],
                        decoration: InputDecoration(
                          labelText: 'Grade',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items:
                            gradeOptions
                                .map(
                                  (grade) => DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGrades[index] = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: calculateGPA,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Calculate GPA",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color set to white
                ),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "GPA Calculator",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: BackButton(),
        backgroundColor: Color.fromARGB(255, 21, 101, 192),
        elevation: 4,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: showInitialInput ? buildInitialInputUI() : buildSubjectForm(),
      ),
    );
  }
}
