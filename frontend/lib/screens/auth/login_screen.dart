import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAdminLogin = false;
  bool isLoginMode = false; // Toggle between Login and Signup
  int signupStep = 1;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Login specific controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  String completePhoneNumber = '';
  final String backendUrl = 'https://mychat-vq7q.onrender.com';
  bool isLoading = false;

  Future<void> _saveTokenAndNavigate(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListScreen(isAdmin: false)));
  }

  Future<void> _handleLogin() async {
    if (isAdminLogin) {
      if (_loginEmailController.text == 'admin@mychat.com' && _loginPasswordController.text == 'admin123') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListScreen(isAdmin: true)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin Credentials')));
      }
      return;
    }

    if (_loginEmailController.text.isEmpty || _loginPasswordController.text.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': _loginEmailController.text,
          'password': _loginPasswordController.text,
          'deviceId': 'web-browser-123'
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveTokenAndNavigate(data['accessToken']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email or password')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    if (signupStep == 1) {
      if (_nameController.text.isEmpty || _emailController.text.isEmpty || completePhoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }
      setState(() => isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$backendUrl/auth/send-email-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': _emailController.text}),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() => signupStep = 2);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => isLoading = false);
      }
    } else if (signupStep == 2) {
      if (_otpController.text.isEmpty) return;
      setState(() => isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$backendUrl/auth/verify-email-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': _emailController.text, 'otp': _otpController.text}),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() => signupStep = 3);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email verified! Create a password.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP code')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => isLoading = false);
      }
    } else if (signupStep == 3) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
        return;
      }
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
        return;
      }
      setState(() => isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$backendUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phoneNumber': completePhoneNumber,
            'email': _emailController.text,
            'password': _passwordController.text,
            'fullName': _nameController.text,
            'deviceId': 'web-browser-123'
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          await _saveTokenAndNavigate(data['accessToken']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to register: ${response.body}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyCHAT', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2C34),
        actions: [
          TextButton(
            onPressed: () => setState(() => isAdminLogin = !isAdminLogin),
            child: Text(isAdminLogin ? 'User Login' : 'Admin Login', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      backgroundColor: const Color(0xFF121B22),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 80, color: Color(0xFF00A884)),
                const SizedBox(height: 20),
                Text(
                  isAdminLogin ? 'Admin Access' : (isLoginMode ? 'Welcome Back' : 'Create Account'),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                
                if (isAdminLogin || isLoginMode) ...[
                  TextField(
                    controller: _loginEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _loginPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF00A884))
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A884),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                ] else ...[
                  if (signupStep == 1) ...[
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 20),
                    IntlPhoneField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white),
                      dropdownTextStyle: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Phone number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      initialCountryCode: 'IN',
                      pickerDialogStyle: PickerDialogStyle(width: 400),
                      onChanged: (phone) => completePhoneNumber = phone.completeNumber,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email)),
                    ),
                  ],
                  if (signupStep == 2) ...[
                    const Text('Enter the 6-digit code sent to your email', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Email OTP Code', prefixIcon: Icon(Icons.message)),
                    ),
                  ],
                  if (signupStep == 3) ...[
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Create Password', prefixIcon: Icon(Icons.lock)),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
                    ),
                  ],
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF00A884))
                      : ElevatedButton(
                          onPressed: _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A884),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            signupStep == 1 ? 'Send Email OTP' : (signupStep == 2 ? 'Verify OTP' : 'Complete Registration'),
                            style: const TextStyle(fontSize: 16)
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
