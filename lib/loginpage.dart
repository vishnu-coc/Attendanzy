import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'changepassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  mongo.Db? _db;

  final List<String> _roles = ['User', 'Staff', 'HOD'];
  final List<String> _departments = [
    'Computer Science',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Electronics and Communication Engineering',
    'Information Technology',
  ];
  int _selectedRoleIndex = 0;
  int _selectedDepartmentIndex = 0;

  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB?retryWrites=true&w=majority";

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _checkLoginStatus();
  }

  Future<void> debugSharedPreferences(String location) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final name = prefs.getString('name');
    final role = prefs.getString('role');
    final isStaff = prefs.getBool('isStaff');
    print(
      'DEBUG [$location]: email=$email, name=$name, role=$role, isStaff=$isStaff',
    );
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  Future<void> _initializeDatabase() async {
    try {
      print('Connecting to MongoDB...');
      _db = await mongo.Db.create(mongoUri);
      await _db!.open();
      print('Connected to MongoDB');
    } catch (e) {
      print('Failed to connect to MongoDB: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    await debugSharedPreferences('_checkLoginStatus start');
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final name = prefs.getString('name');
    final role = prefs.getString('role') ?? '';
    final isStaff = prefs.getBool('isStaff') ?? false;

    if (email != null && name != null && role.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => HomePage(
                name: name,
                email: email,
                profile: {},
                isStaff: isStaff,
                role: role,
              ),
        ),
      );
    }
  }

  void _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String selectedRole = _roles[_selectedRoleIndex].toLowerCase();
    String selectedDepartment = _departments[_selectedDepartmentIndex];

    print(
      'Login attempt: email=$email, role=$selectedRole, department=$selectedDepartment',
    );

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        late String collectionName;
        if (selectedRole == 'user') {
          collectionName = 'profile';
        } else if (selectedRole == 'staff') {
          collectionName = 'Staff';
        } else if (selectedRole == 'hod') {
          collectionName = 'HOD';
        } else {
          collectionName = 'profile'; // fallback
        }

        final collection = _db!.collection(collectionName);

        // Query fields use lowercase keys per DB
        final query = {
          "email": {"\$regex": "^$email\$", "\$options": "i"},
          "password": password,
          "role": selectedRole,
          "department": selectedDepartment,
        };

        final user = await collection.findOne(query);

        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          print('User found: $user');
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString(
            'email',
            user["email"] ?? user["College Email"] ?? '',
          );
          await prefs.setString('name', user["name"] ?? user["Name"] ?? '');
          await prefs.setBool(
            'isStaff',
            selectedRole == 'staff' || selectedRole == 'hod',
          );
          await prefs.setString('role', selectedRole);
          await prefs.setString('department', selectedDepartment);

          // >>> Store year and section for student <<<
          if (selectedRole == 'user') {
            final year = user['year'] ?? '';
            final section = user['sec'] ?? '';
            await prefs.setString('year', year);
            await prefs.setString('section', section);
            print('DEBUG [Login]: Stored year=$year, section=$section');
          }

          await debugSharedPreferences('After saving to SharedPreferences');

          bool isFirstLogin = false;
          final firstLoginValue = user['firstLogin'];
          if (firstLoginValue is bool) {
            isFirstLogin = firstLoginValue;
          } else if (firstLoginValue is String) {
            isFirstLogin = firstLoginValue.toLowerCase() == 'true';
          }

          if (selectedRole == 'user' && isFirstLogin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ChangePasswordPage(
                      email: user["email"] ?? user["College Email"] ?? '',
                      db: _db,
                      collectionName: collectionName,
                      isStaff: false,
                    ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HomePage(
                      name: user["name"] ?? user["Name"] ?? '',
                      email: user["email"] ?? user["College Email"] ?? '',
                      profile: user,
                      isStaff: selectedRole == 'staff' || selectedRole == 'hod',
                      role: selectedRole,
                    ),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage =
                'Invalid credentials. Please check your email, password, role, and department.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to connect to the database.';
        });
        print('Login Error: $e');
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please fill in all fields.';
      });
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Login to continue',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  _emailController,
                  'College Email',
                  Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 20),
                _buildRoleDropdown(),
                const SizedBox(height: 20),
                _buildDepartmentDropdown(),
                const SizedBox(height: 10),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed:
                () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedRoleIndex,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(fontSize: 16, color: Colors.black),
          items: List.generate(
            _roles.length,
            (index) =>
                DropdownMenuItem(value: index, child: Text(_roles[index])),
          ),
          onChanged:
              (int? value) => setState(() => _selectedRoleIndex = value ?? 0),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDepartmentIndex,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(fontSize: 16, color: Colors.black),
          items: List.generate(
            _departments.length,
            (index) => DropdownMenuItem<int>(
              value: index,
              child: Text(_departments[index]),
            ),
          ),
          onChanged:
              (int? value) =>
                  setState(() => _selectedDepartmentIndex = value ?? 0),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _login,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          decoration: BoxDecoration(
            color:
                _isLoading ? const Color(0xFFDED864) : const Color(0xFFBEAA07),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _isLoading
                ? 'Logging in...'
                : 'Login as ${_roles[_selectedRoleIndex]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
