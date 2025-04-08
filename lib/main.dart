import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'staff_availability_display_page.dart';
import 'chat.dart'; // Assuming this is your ChatAI class
import 'ChatMessage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCSBUlynRalqW8Xdx-40GfBp8UsDStzhxE",
      authDomain: "sist-d464f.firebaseapp.com",
      databaseURL: "https://sist-d464f-default-rtdb.firebaseio.com",
      projectId: "sist-d464f",
      storageBucket: "sist-d464f.firebasestorage.app",
      messagingSenderId: "932406242298",
      appId: "1:932406242298:web:f77e52c3c7e07968ba1243",
      measurementId: "G-P43614W1CB"
    ),
  );
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
      home: AuthenticationWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/chat': (context) => ChatAI(),
        '/staffAvailabilityDisplay': (context) => StaffAvailabilityDisplayPage(),
        '/home': (context) => HomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/profile') {
          final args = settings.arguments as Map<String, dynamic>;
          final userId = args['userId'];
          return MaterialPageRoute(
            builder: (context) => ProfilePage(userId: userId),
          );
        }
        return null;
      },
    );
  }
}

// AuthenticationWrapper to handle authentication state
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return LoginPage();
          }
          return HomePage();
        }

        // Show loading indicator while checking auth state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// Data models
class Post {
  final String id;
  final String content;
  final String userId;
  final String authorName;
  final String authorProfilePic;
  final DateTime datePosted;
  final int likes;

  Post({
    required this.id,
    required this.content,
    required this.userId,
    required this.authorName,
    required this.authorProfilePic,
    required this.datePosted,
    required this.likes,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'userId': userId,
      'authorName': authorName,
      'authorProfilePic': authorProfilePic,
      'datePosted': datePosted.toIso8601String(),
      'likes': likes,
    };
  }

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      content: map['content'] ?? '',
      userId: map['userId'] ?? '',
      authorName: map['authorName'] ?? 'Anonymous',
      authorProfilePic: map['authorProfilePic'] ?? 'https://i.pravatar.cc/150',
      datePosted: DateTime.parse(map['datePosted']),
      likes: map['likes'] ?? 0,
    );
  }
}

// Service for posts
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new post
  Future<void> createPost(String content) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      // Default values if user profile doesn't exist
      final userData = userDoc.exists
          ? userDoc.data() as Map<String, dynamic>
          : {
              'username': currentUser.email?.split('@')[0] ?? 'Anonymous',
              'profilePictureUrl': 'https://i.pravatar.cc/150',
            };

      // Create post data
      final postData = {
        'content': content,
        'userId': currentUser.uid,
        'authorName': userData['username'] ?? 'Anonymous',
        'authorProfilePic': userData['profilePictureUrl'] ?? 'https://i.pravatar.cc/150',
        'datePosted': DateTime.now().toIso8601String(),
        'likes': 0,
      };

      // Save the post to Firestore
      await _firestore.collection('posts').add(postData);
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Get posts for the feed
  Stream<QuerySnapshot> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('datePosted', descending: true)
        .snapshots();
  }
}

// User service to handle user data
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create user in Firestore after signup
  Future<void> createUserInFirestore(User user) async {
    try {
      final userData = {
        'email': user.email,
        'username': user.email?.split('@')[0] ?? 'Anonymous',
        'fullname': 'New User',
        'profilePictureUrl': 'https://i.pravatar.cc/150',
        'dateCreated': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
    } catch (e) {
      print('Error creating user in Firestore: $e');
      rethrow;
    }
  }

  // Get current user data
  Future<DocumentSnapshot?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return await _firestore.collection('users').doc(user.uid).get();
  }
}