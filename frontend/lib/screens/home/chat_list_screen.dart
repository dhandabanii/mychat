import 'package:flutter/material.dart';
import '../chat/chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, String>> dummyChats = [
    {'name': 'John Doe', 'msg': 'Hey, how are you?', 'time': '10:30 AM'},
    {'name': 'Jane Smith', 'msg': 'Are we still on for today?', 'time': '09:15 AM'},
    {'name': 'Work Group', 'msg': 'Alice: Please review the doc', 'time': 'Yesterday'},
    {'name': 'Mom', 'msg': 'Call me when you are free.', 'time': 'Yesterday'},
  ];

  String? selectedChatUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // LAPTOP / WEB VIEW (SPLIT SCREEN)
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildChatList(isDesktop: true),
              ),
              Container(
                width: 1,
                color: Colors.grey.shade900,
              ),
              Expanded(
                flex: 7,
                child: selectedChatUser == null
                    ? Scaffold(
                        body: Container(
                          color: const Color(0xFF222E35),
                          child: const Center(
                            child: Text(
                              'WhatsApp for Web\nSelect a chat to start messaging',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                      )
                    : ChatDetailScreen(userName: selectedChatUser!),
              ),
            ],
          );
        }

        // MOBILE VIEW
        return _buildChatList(isDesktop: false);
      },
    );
  }

  Widget _buildChatList({required bool isDesktop}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Clone', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF202C33),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: dummyChats.length,
        itemBuilder: (context, index) {
          final chat = dummyChats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tileColor: selectedChatUser == chat['name'] && isDesktop ? const Color(0xFF2A3942) : null,
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade800,
              child: Icon(Icons.person, color: Colors.grey.shade400, size: 30),
            ),
            title: Text(
              chat['name']!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                chat['msg']!,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Text(
              chat['time']!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              if (isDesktop) {
                setState(() {
                  selectedChatUser = chat['name'];
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(userName: chat['name']!),
                  ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.message),
      ),
    );
  }
}
