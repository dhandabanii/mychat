import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../home/chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAdminLogin = false;
  int loginStep = 1;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();

  String completePhoneNumber = '';
  ConfirmationResult? _confirmationResult;

  Future<void> _login() async {
    if (isAdminLogin) {
      if (_emailController.text == 'admin@mychat.com' && _passwordController.text == 'admin123') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListScreen(isAdmin: true)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin Credentials')));
      }
    } else {
      if (loginStep == 1) {
        if (completePhoneNumber.isNotEmpty) {
          try {
            // Firebase Phone Auth for Web requires the full international number
            _confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
              completePhoneNumber,
            );
            setState(() => loginStep = 2);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Real OTP SMS sent!')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
          }
        }
      } else if (loginStep == 2) {
        if (_otpController.text.isNotEmpty && _confirmationResult != null) {
          try {
            await _confirmationResult!.confirm(_otpController.text);
            setState(() => loginStep = 3);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone Verified! Please create a password.')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP code!')));
          }
        }
      } else if (loginStep == 3) {
        if (_userPasswordController.text.isNotEmpty) {
          try {
            final String backendUrl = 'https://mychat-vq7q.onrender.com';
            final String phone = completePhoneNumber;
            final String password = _userPasswordController.text;

            // Try to Register
            final regResponse = await http.post(
              Uri.parse('$backendUrl/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'phoneNumber': phone,
                'password': password,
                'fullName': 'User $phone',
                'deviceId': 'web-browser-123'
              })
            );

            if (regResponse.statusCode == 201 || regResponse.statusCode == 200) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListScreen(isAdmin: false)));
            } else if (regResponse.statusCode == 409) {
              // User already exists, try Login
              final loginResponse = await http.post(
                Uri.parse('$backendUrl/auth/login'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'identifier': phone,
                  'password': password,
                  'deviceId': 'web-browser-123'
                })
              );

              if (loginResponse.statusCode == 201 || loginResponse.statusCode == 200) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListScreen(isAdmin: false)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password for existing user!')));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backend Error: ${regResponse.body}')));
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: $e')));
          }
        }
      }
    }
  }

  String _getButtonText() {
    if (isAdminLogin) return 'Login';
    if (loginStep == 1) return 'Get OTP';
    if (loginStep == 2) return 'Verify OTP';
    return 'Save & Login';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyCHAT Login'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              isAdminLogin = !isAdminLogin;
              loginStep = 1; // reset on switch
            }),
            child: Text(isAdminLogin ? 'User Login' : 'Admin Login', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 80, color: Color(0xFF00A884)),
                  const SizedBox(height: 32),
                  Text(
                    isAdminLogin ? 'Admin Portal' : (loginStep == 1 ? 'Enter your phone number' : loginStep == 2 ? 'Enter OTP' : 'Create a Password'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (isAdminLogin) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Admin Email', prefixIcon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Admin Password', prefixIcon: Icon(Icons.lock)),
                    ),
                  ] else ...[
                    if (loginStep == 1)
                      IntlPhoneField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        initialCountryCode: 'IN', // Default to India
                        onChanged: (phone) {
                          completePhoneNumber = phone.completeNumber;
                        },
                      ),
                    if (loginStep == 2)
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '6-digit OTP', prefixIcon: Icon(Icons.message)),
                      ),
                    if (loginStep == 3)
                      TextField(
                        controller: _userPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(hintText: 'New Password', prefixIcon: Icon(Icons.lock)),
                      ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(_getButtonText(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
