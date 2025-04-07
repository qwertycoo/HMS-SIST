import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class ChatAI extends StatefulWidget {
  @override
  _DiscordChatAIState createState() => _DiscordChatAIState();
}

class _DiscordChatAIState extends State<ChatAI> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  late IOWebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    channel = IOWebSocketChannel.connect("ws://localhost:8080");
    channel.stream.listen((message) {
      final decoded = jsonDecode(message);
      setState(() {
        messages.add({"username": decoded["username"], "content": decoded["content"]});
      });
    });
  }

  Future<void> sendMessage(String text) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/send-message'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": text}),
    );

    if (response.statusCode == 200) {
      print("✅ Message sent to Discord!");
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with Discord AI Bot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]["username"]!, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(messages[index]["content"]!),
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
                    decoration: InputDecoration(labelText: "Type a message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
