import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'loginpage.dart'; // Import the LoginPage

class ChangePasswordPage extends StatefulWidget {
  final String email;
  final bool isStaff;
  final mongo.Db? db;
  final String collectionName; // MongoDB database instance

  const ChangePasswordPage({
    super.key,
    required this.email,
    this.db,
    required this.isStaff,
    required this.collectionName,
  });

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _errorMessage = '';
  bool _isNewPasswordVisible = false; // To toggle visibility of new password
  bool _isConfirmPasswordVisible =
      false; // To toggle visibility of confirm password

  Future<void> _ensureDbOpen() async {
    if (widget.db?.state != mongo.State.OPEN) {
      try {
        print('Reopening MongoDB connection...');
        await widget.db!.open();
        print('MongoDB connection reopened.');
      } catch (e) {
        print('Failed to reopen MongoDB connection: $e');
        throw Exception('Failed to connect to the database.');
      }
    }
  }

  void _updatePassword() async {
    setState(() {
      _errorMessage = '';
    });

    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    try {
      // Ensure the database connection is open
      await _ensureDbOpen();

      final collection = widget.db!.collection('profile');

      // Debug: Print the email and new password
      print('Updating password for email: ${widget.email}');
      print('New password: $newPassword');

      // Update the user's password and set isPasswordChanged to true
      final result = await collection.updateOne(
        {
          "College Email ": {"\$regex": "^${widget.email}\$", "\$options": "i"},
        },
        {
          "\$set": {
            "Password": newPassword, // Store password as a string
            "isPasswordChanged": true,
          },
        },
      );

      // Debug: Print the result of the update operation
      print('Update result: ${result.isSuccess}');

      if (result.isSuccess) {
        // Redirect to LoginPage after successful password update
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update password. Please try again.';
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD194), Color(0xFF70E1F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Set a new password to continue',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    hintText: 'New Password',
                    obscureText: !_isNewPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                    isPasswordVisible: _isNewPasswordVisible,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm New Password',
                    obscureText: !_isConfirmPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    isPasswordVisible: _isConfirmPasswordVisible,
                  ),
                  const SizedBox(height: 10),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 190, 166, 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Update Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isPasswordVisible,
  }) {
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
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }
}
