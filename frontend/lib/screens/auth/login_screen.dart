import 'package:flutter/material.dart';
import '../home/chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAdminLogin = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _login() {
    // Basic navigation for now
    if (isAdminLogin) {
      if (_emailController.text == 'admin@mychat.com' && _passwordController.text == 'admin123') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListScreen(isAdmin: true)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin Credentials')));
      }
    } else {
      if (_phoneController.text.isNotEmpty) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListScreen(isAdmin: false)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyCHAT Login'),
        actions: [
          TextButton(
            onPressed: () => setState(() => isAdminLogin = !isAdminLogin),
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
                    isAdminLogin ? 'Admin Portal' : 'Enter your phone number',
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
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Phone number', prefixIcon: Icon(Icons.phone)),
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
                    child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
