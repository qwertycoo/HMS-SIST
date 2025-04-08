import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late Stream<QuerySnapshot> _postsStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _postsStream = _firestore
        .collection('posts')
        .orderBy('datePosted', descending: true)
        .snapshots();
  }

  // Helper function to format time ago
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Show modal bottom sheet to create a post
  void _showCreatePostSheet() {
    final TextEditingController postController = TextEditingController();
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: postController,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (postController.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.pop(context);

                      try {
                        setState(() {
                          _isLoading = true;
                        });

                        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

                        // Use userData if available, otherwise use defaults
                        final userData = userDoc.exists
                            ? userDoc.data() as Map<String, dynamic>
                            : {
                                'username': currentUser.email?.split('@')[0] ?? 'Anonymous',
                                'profilePictureUrl': 'https://i.pravatar.cc/150',
                              };

                        // Save post to Firebase posts collection
                        await _firestore.collection('posts').add({
                          'content': postController.text.trim(),
                          'userId': currentUser.uid,
                          'authorName': userData['username'] ?? 'Anonymous',
                          'authorProfilePic': userData['profilePictureUrl'] ?? 'https://i.pravatar.cc/150',
                          'datePosted': DateTime.now().toIso8601String(),
                          'likes': 0,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post created successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating post: $e')),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: const Text('Post'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'University Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _initializeStream();
                });
              },
              child: Column(
                children: [
                  // Create post card
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('users').doc(_auth.currentUser?.uid ?? '').get(),
                            builder: (context, snapshot) {
                              final userData = snapshot.data?.data() as Map<String, dynamic>?;
                              return CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  userData?['profilePictureUrl'] ?? 'https://i.pravatar.cc/150',
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _showCreatePostSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  "What's on your mind?",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Posts list
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _postsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No posts yet. Be the first to post!'));
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final postData = doc.data() as Map<String, dynamic>;
                            final datePosted = DateTime.parse(postData['datePosted']);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Post header with profile navigation
                                  ListTile(
                                    onTap: () {
                                      // Navigate to profile page when user info is clicked
                                      Navigator.pushNamed(
                                        context,
                                        '/profile',
                                        arguments: {'userId': postData['userId']},
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(postData['authorProfilePic'] ?? 'https://i.pravatar.cc/150'),
                                    ),
                                    title: Text(
                                      postData['authorName'] ?? 'Anonymous',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      _getTimeAgo(datePosted),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  // Post content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(postData['content'] ?? ''),
                                  ),

                                  // Post engagement section
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.thumb_up_outlined,
                                            size: 20,
                                            color: Colors.blue[400],
                                          ),
                                          onPressed: () async {
                                            // Simple like functionality
                                            if (_auth.currentUser != null) {
                                              await _firestore.collection('posts').doc(doc.id).update({
                                                'likes': FieldValue.increment(1),
                                              });
                                            }
                                          },
                                        ),
                                        Text(
                                          '${postData['likes'] ?? 0}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        child: const Icon(Icons.create),
        backgroundColor: Colors.blue,
      ),
    );
  }
}