import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  String senderId;
  String message;
  int timestamp;
  String receiverId;

  ChatMessage({
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.receiverId,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'message': message,
        'timestamp': timestamp,
        'receiverId': receiverId,
      };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
        senderId: json['senderId'],
        message: json['message'],
        timestamp: json['timestamp'],
        receiverId: json['receiverId'],
      );
}

// User selection screen
class ChatUserSelectionScreen extends StatelessWidget {
  const ChatUserSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User to Chat'),
        backgroundColor: Colors.blue[600],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').get().asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Filter out current user
          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser?.uid)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users available'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    userData['profilePictureUrl'] ?? 'https://i.pravatar.cc/150',
                  ),
                ),
                title: Text(userData['username'] ?? 'User'),
                subtitle: Text(userData['email'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(receiverId: userId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({Key? key, required this.receiverId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _db = FirebaseDatabase.instance.ref();
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser!;
  List<ChatMessage> _messages = [];
  String _receiverName = 'User';
  String _receiverProfilePic = 'https://i.pravatar.cc/150';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceiverInfo();
    _listenToMessages();
  }

  Future<void> _loadReceiverInfo() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.receiverId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _receiverName = userData['username'] ?? 'User';
          _receiverProfilePic = userData['profilePictureUrl'] ?? 'https://i.pravatar.cc/150';
        });
      }
    } catch (e) {
      print('Error loading receiver info: $e');
    }
  }

  void _listenToMessages() {
    // Create a unique conversation ID to store messages between these two users
    final String conversationId = _getConversationId(_user.uid, widget.receiverId);

    _db.child("conversations/$conversationId").onValue.listen((event) {
      setState(() {
        _isLoading = false;
      });

      if (event.snapshot.value == null) {
        setState(() {
          _messages = [];
        });
        return;
      }

      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final msgs = data.entries
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e.value)))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _messages = msgs;
        });
      } catch (e) {
        print('Error parsing messages: $e');
        setState(() {
          _messages = [];
        });
      }
    });
  }

  // Create a consistent conversation ID regardless of who initiated the chat
  String _getConversationId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final conversationId = _getConversationId(_user.uid, widget.receiverId);

      final msg = ChatMessage(
        senderId: _user.uid,
        receiverId: widget.receiverId,
        message: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      _db.child("conversations/$conversationId").push().set(msg.toJson());

      // Update last message for chat list
      _firestore.collection('chatList').doc(_user.uid).collection('chats').doc(widget.receiverId).set({
        'lastMessage': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': widget.receiverId,
      });

      // Update for receiver as well
      _firestore.collection('chatList').doc(widget.receiverId).collection('chats').doc(_user.uid).set({
        'lastMessage': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': _user.uid,
      });

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
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_receiverProfilePic),
              radius: 16,
            ),
            const SizedBox(width: 8),
            Text(_receiverName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('No messages yet. Start a conversation!'))
                      : ListView(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          children: _messages.map(_buildMessage).toList(),
                        ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }
}

// Chat list screen to show all conversations
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatUserSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('chatList')
            .doc(currentUser?.uid)
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No conversations yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatUserSelectionScreen()),
                      );
                    },
                    child: const Text('Start a new chat'),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final otherUserId = chatData['userId'];

              return FutureBuilder<DocumentSnapshot>(
                future: firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final username = userData?['username'] ?? 'User';
                  final profilePic = userData?['profilePictureUrl'] ?? 'https://i.pravatar.cc/150';
                  final lastMessage = chatData['lastMessage'];
                  final timestamp = chatData['timestamp'] as int;
                  final time = DateFormat('MMM d, h:mm a').format(
                    DateTime.fromMillisecondsSinceEpoch(timestamp),
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(profilePic),
                    ),
                    title: Text(username),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      time,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(receiverId: otherUserId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatUserSelectionScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat),
      ),
    );
  }
}