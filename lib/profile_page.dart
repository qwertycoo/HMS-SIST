import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final String userId; // Can be current user or another user's ID

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<DocumentSnapshot> _userStream;
  late Stream<QuerySnapshot> _postsStream;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == _auth.currentUser?.uid;
    _userStream = _firestore.collection('users').doc(widget.userId).snapshots();
    _postsStream = _firestore
        .collection('posts')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('datePosted', descending: true)
        .snapshots();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return Text(userData['username'] ?? 'Profile');
          }
        ),
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit profile page
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          StreamBuilder<DocumentSnapshot>(
            stream: _userStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile picture
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        userData['profilePictureUrl'] ?? 'https://i.pravatar.cc/150'
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User name
                    Text(
                      userData['fullName'] ?? userData['username'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // User role
                    Text(
                      userData['role'] ?? 'Member',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),

                    if (userData['summary'] != null && userData['summary'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          userData['summary'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Divider(),
                  ],
                ),
              );
            }
          ),

          // Posts header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: const [
                Text(
                  'Posts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Posts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isCurrentUser
                              ? 'You haven\'t posted anything yet'
                              : 'This user hasn\'t posted anything yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final postData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final postId = snapshot.data!.docs[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post header
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(postData['authorProfilePic'] ?? 'https://i.pravatar.cc/150'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        postData['authorName'] ?? 'Anonymous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _getTimeAgo(DateTime.parse(postData['datePosted'])),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isCurrentUser)
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      // Show options for user's own post
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.edit),
                                                title: const Text('Edit Post'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  // Navigate to edit post
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.delete, color: Colors.red),
                                                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  // Show delete confirmation
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text('Delete Post'),
                                                        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
                                                        actions: [
                                                          TextButton(
                                                            child: const Text('Cancel'),
                                                            onPressed: () => Navigator.pop(context),
                                                          ),
                                                          TextButton(
                                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                            onPressed: () {
                                                              // Delete post
                                                              _firestore.collection('posts').doc(postId).delete();
                                                              Navigator.pop(context);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),

                          // Post content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Text(postData['content'] ?? ''),
                          ),

                          // Post stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.thumb_up,
                                  size: 16,
                                  color: Colors.blue[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (postData['likes'] ?? 0).toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                // Add comment count here if needed
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          // Post actions
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  icon: Icon(
                                    Icons.thumb_up_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  label: Text(
                                    'Like',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onPressed: () {
                                    // Like post functionality
                                  },
                                ),
                                TextButton.icon(
                                  icon: Icon(
                                    Icons.comment_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  label: Text(
                                    'Comment',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onPressed: () {
                                    // Comment functionality
                                  },
                                ),
                                TextButton.icon(
                                  icon: Icon(
                                    Icons.share_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  label: Text(
                                    'Share',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onPressed: () {
                                    // Share functionality
                                  },
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
    );
  }
}