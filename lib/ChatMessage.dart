import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatMessage {
  String senderId;
  String message;
  int timestamp;

  ChatMessage({required this.senderId, required this.message, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'message': message,
        'timestamp': timestamp,
      };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
        senderId: json['senderId'],
        message: json['message'],
        timestamp: json['timestamp'],
      );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _db = FirebaseDatabase.instance.ref("messages");
  final _user = FirebaseAuth.instance.currentUser!;
  List<ChatMessage> _messages = [];
  late int sessionStartTime;

  @override
  void initState() {
    super.initState();
    sessionStartTime = DateTime.now().millisecondsSinceEpoch;

    _db.orderByChild("timestamp").onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final msgs = data.entries
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e.value)))
          .where((msg) => msg.timestamp >= sessionStartTime)
          .toList();

      setState(() => _messages = msgs);
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final msg = ChatMessage(
        senderId: _user.uid,
        message: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _db.push().set(msg.toJson());
      _controller.clear();
    }
  }

  Widget _buildMessage(ChatMessage msg) {
    final isMe = msg.senderId == _user.uid;
    final time = DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Type a message...",
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        title: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: _messages.reversed.map(_buildMessage).toList(),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}
