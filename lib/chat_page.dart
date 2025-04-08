import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      // Handle sending the message using the `ChatMessage` model
      final msg = ChatMessage(
        senderId: 'currentUserId',  // Use the actual current user ID here
        receiverId: widget.receiverId,
        message: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // Firebase logic to save the message would go here

      _controller.clear();  // Clear the input after sending the message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.receiverName}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 0, // Replace with the actual message list count
              itemBuilder: (context, index) {
                // Display messages in a ListView
                return ListTile(
                  title: Text("Message content"), // Render actual messages here
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Enter your message",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
