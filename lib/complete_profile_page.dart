import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// A page for completing the user's profile after signup.
/// Some fields are required (Full Name, Headline, Location), while others can be skipped.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({Key? key}) : super(key: key);

  @override
  CompleteProfilePageState createState() => CompleteProfilePageState();
}

class CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for profile fields.
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController headlineController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  bool isLoading = false;

  /// Saves the completed profile data to Firebase Realtime Database.
  /// The "skills" field is stored as a list (splitting a comma-separated string).
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference ref =
          FirebaseDatabase.instance.ref("users/${user.uid}");
      try {
        await ref.update({
          'fullName': fullNameController.text.trim(),
          'headline': headlineController.text.trim(),
          'location': locationController.text.trim(),
          'summary': summaryController.text.trim(),
          'skills': skillsController.text.trim().isNotEmpty
              ? skillsController.text
                  .trim()
                  .split(',')
                  .map((skill) => skill.trim())
                  .toList()
              : [],
          'experience': [],    
          'education': [],     
          'contact': {}           
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Navigate to the profile page (or home) after saving.
        Navigator.pushReplacementNamed(context, '/profile');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers when no longer needed.
    fullNameController.dispose();
    headlineController.dispose();
    locationController.dispose();
    summaryController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              // Full Name (required)
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Headline (required)
              TextFormField(
                controller: headlineController,
                decoration: const InputDecoration(
                  labelText: 'Headline *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Headline is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Location (required)
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Summary (optional)
              TextFormField(
                controller: summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              // Skills (optional) - enter skills separated by commas.
              TextFormField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Flutter, Firebase, Dart',
                ),
              ),
              const SizedBox(height: 20),
              // Save profile button.
              ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Profile'),
              ),
              const SizedBox(height: 10),
              // Option to skip profile completion.
              TextButton(
                onPressed: () {
                  // Navigate to profile page if the user decides to complete later.
                  Navigator.pushReplacementNamed(context, '/profile');
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
