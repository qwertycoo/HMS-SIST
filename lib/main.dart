import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat.dart'; // Import the chat screen


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniversityApp());
}

class UniversityApp extends StatelessWidget {
  const UniversityApp({Key? key}) : super(key: key);

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Community',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: const HomePage(),
      routes: {
          '/chat': (context) => ChatScreen(), // Register ChatScreen route
        },
    );
  }
}

// Models based on the ERD
class User {
  final int userId;
  final String username;
  final String email;
  final String role;
  final String profilePicUrl;
  final DateTime dateCreated;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.profilePicUrl,
    required this.dateCreated,
  });
}

class Post {
  final int postId;
  final String content;
  final User author;
  final DateTime datePosted;
  final List<Comment> comments;
  final int likes;
  bool isLiked;
  bool isSaved;

  Post({
    required this.postId,
    required this.content,
    required this.author,
    required this.datePosted,
    required this.comments,
    required this.likes,
    this.isLiked = false,
    this.isSaved = false,
  });
}

class Comment {
  final int commentId;
  final String content;
  final User author;
  final DateTime datePosted;

  Comment({
    required this.commentId,
    required this.content,
    required this.author,
    required this.datePosted,
  });
}

class Event {
  final int eventId;
  final String title;
  final DateTime date;
  final String location;
  final String description;
  final List<User> attendees;

  Event({
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.attendees,
  });
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<Post> _posts = [];

  // Current user (in a real app, this would come from authentication)
  late User currentUser;

  @override
  void initState() {
    super.initState();
    // Simulate loading data
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulating API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Create mock data
    currentUser = User(
      userId: 1,
      username: "john.doe",
      email: "john.doe@university.edu",
      role: "Student",
      profilePicUrl: "https://i.pravatar.cc/150?img=1",
      dateCreated: DateTime.now().subtract(const Duration(days: 365)),
    );



    final List<User> users = [
      currentUser,
      User(
        userId: 2,
        username: "prof.smith",
        email: "smith@university.edu",
        role: "Staff",
        profilePicUrl: "https://i.pravatar.cc/150?img=2",
        dateCreated: DateTime.now().subtract(const Duration(days: 500)),
      ),
      User(
        userId: 3,
        username: "emma.wilson",
        email: "emma@university.edu",
        role: "Student",
        profilePicUrl: "https://i.pravatar.cc/150?img=3",
        dateCreated: DateTime.now().subtract(const Duration(days: 200)),
      ),
      User(
        userId: 4,
        username: "admin.tech",
        email: "admin@university.edu",
        role: "Admin",
        profilePicUrl: "https://i.pravatar.cc/150?img=4",
        dateCreated: DateTime.now().subtract(const Duration(days: 700)),
      ),
    ];




    // Generate mock posts
    final List<Post> posts = [
      Post(
        postId: 1,
        content: "Just finished my research paper on machine learning applications in educational technology! Looking forward to presenting at the upcoming conference.",
        author: users[1],
        datePosted: DateTime.now().subtract(const Duration(hours: 3)),
        comments: [
          Comment(
            commentId: 1,
            content: "Sounds interesting! Can't wait to read it.",
            author: users[2],
            datePosted: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          Comment(
            commentId: 2,
            content: "Would love to discuss this further. Are you free for coffee tomorrow?",
            author: users[0],
            datePosted: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
        likes: 15,
      ),
      Post(
        postId: 2,
        content: "Reminder: Student Council applications are due next Friday! Don't miss this opportunity to make a difference on campus.",
        author: users[3],
        datePosted: DateTime.now().subtract(const Duration(days: 1)),
        comments: [
          Comment(
            commentId: 3,
            content: "Is there a word limit for the essay portion?",
            author: users[2],
            datePosted: DateTime.now().subtract(const Duration(hours: 12)),
          ),
        ],
        likes: 8,
      ),
      Post(
        postId: 3,
        content: "Just passed my final exams with flying colors! Hard work really does pay off. Now it's time to celebrate! 🎉",
        author: users[2],
        datePosted: DateTime.now().subtract(const Duration(days: 2)),
        comments: [],
        likes: 27,
      ),
      Post(
        postId: 4,
        content: "The university library will be extended opening hours during finals week. We'll be open until midnight starting next Monday.",
        author: users[1],
        datePosted: DateTime.now().subtract(const Duration(days: 3)),
        comments: [
          Comment(
            commentId: 4,
            content: "Thank you! This will be incredibly helpful.",
            author: users[2],
            datePosted: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        likes: 42,
      ),
    ];

    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  void _likePost(int postId) {
    setState(() {
      final postIndex = _posts.indexWhere((post) => post.postId == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        if (post.isLiked) {
          _posts[postIndex] = Post(
            postId: post.postId,
            content: post.content,
            author: post.author,
            datePosted: post.datePosted,
            comments: post.comments,
            likes: post.likes - 1,
            isLiked: false,
            isSaved: post.isSaved,
          );
        } else {
          _posts[postIndex] = Post(
            postId: post.postId,
            content: post.content,
            author: post.author,
            datePosted: post.datePosted,
            comments: post.comments,
            likes: post.likes + 1,
            isLiked: true,
            isSaved: post.isSaved,
          );
        }
      }
    });
  }

  void _savePost(int postId) {
    setState(() {
      final postIndex = _posts.indexWhere((post) => post.postId == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = Post(
          postId: post.postId,
          content: post.content,
          author: post.author,
          datePosted: post.datePosted,
          comments: post.comments,
          likes: post.likes,
          isLiked: post.isLiked,
          isSaved: !post.isSaved,
        );
      }
    });
  }

  void _showCommentSheet(BuildContext context, Post post) {
    final commentController = TextEditingController();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    final comment = post.comments[index];
                    return CommentTile(comment: comment);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(currentUser.profilePicUrl),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      // In a real app, this would add the comment to the database
                      if (commentController.text.isNotEmpty) {
                        setState(() {
                          final newComment = Comment(
                            commentId: post.comments.length + 1,
                            content: commentController.text,
                            author: currentUser,
                            datePosted: DateTime.now(),
                          );

                          final postIndex = _posts.indexWhere((p) => p.postId == post.postId);
                          if (postIndex != -1) {
                            final updatedComments = List<Comment>.from(post.comments)..add(newComment);
                            _posts[postIndex] = Post(
                              postId: post.postId,
                              content: post.content,
                              author: post.author,
                              datePosted: post.datePosted,
                              comments: updatedComments,
                              likes: post.likes,
                              isLiked: post.isLiked,
                              isSaved: post.isSaved,
                            );
                          }
                        });
                        commentController.clear();
                        Navigator.pop(context);
                      }
                    },
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

  void _showCreatePostSheet(BuildContext context) {
    final postController = TextEditingController();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(currentUser.profilePicUrl),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentUser.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Add Image'),
                    onPressed: () {
                      // Image picker functionality would go here
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // In a real app, this would save the post to the database
                      if (postController.text.isNotEmpty) {
                        setState(() {
                          final newPost = Post(
                            postId: _posts.length + 1,
                            content: postController.text,
                            author: currentUser,
                            datePosted: DateTime.now(),
                            comments: [],
                            likes: 0,
                          );
                          _posts = [newPost, ..._posts];
                        });
                        postController.clear();
                        Navigator.pop(context);
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
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications page
            },
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/chat');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _posts.length + 1, // +1 for the create post card
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CreatePostCard(
                      currentUser: currentUser,
                      onTap: () => _showCreatePostSheet(context),
                    );
                  }
                  final post = _posts[index - 1];
                  return PostCard(
                    post: post,
                    onLike: () => _likePost(post.postId),
                    onComment: () => _showCommentSheet(context, post),
                    onSave: () => _savePost(post.postId),
                    onShare: () {
                      // Share functionality would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing post...')),
                      );
                    },
                  );
                },
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
                  Navigator.pushNamed(context, '/chat'); // Navigate to Chat Screen
                }, child: const Icon(Icons.create),
                backgroundColor: Colors.blue,
      ),
    );
  }
}

class CreatePostCard extends StatelessWidget {
  final User currentUser;
  final VoidCallback onTap;

  const CreatePostCard({
    Key? key,
    required this.currentUser,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(currentUser.profilePicUrl),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: onTap,
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
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Colors.green),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
  }) : super(key: key);

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
                  backgroundImage: NetworkImage(post.author.profilePicUrl),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${post.author.role} • ${_getTimeAgo(post.datePosted)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // Show post options
                  },
                ),
              ],
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(post.content),
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
                  post.likes.toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (post.comments.isNotEmpty)
                  Text(
                    '${post.comments.length} ${post.comments.length == 1 ? 'comment' : 'comments'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
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
                    post.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: post.isLiked ? Colors.blue : Colors.grey[600],
                  ),
                  label: Text(
                    'Like',
                    style: TextStyle(
                      color: post.isLiked ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                  onPressed: onLike,
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
                  onPressed: onComment,
                ),
                TextButton.icon(
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: post.isSaved ? Colors.purple : Colors.grey[600],
                  ),
                  label: Text(
                    'Save',
                    style: TextStyle(
                      color: post.isSaved ? Colors.purple : Colors.grey[600],
                    ),
                  ),
                  onPressed: onSave,
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
                  onPressed: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({
    Key? key,
    required this.comment,
  }) : super(key: key);

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment.author.profilePicUrl),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.content),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    _getTimeAgo(comment.datePosted),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}