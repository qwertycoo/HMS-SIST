import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Define the primary color using a Twitter-inspired blue.
const Color primaryColor = Color(0xFF1DA1F2);

/// A helper widget that applies both fade and scale transitions to its child
/// with a delay. The fade gives a smooth entrance effect, and the scale
/// introduces a slight bounce (elasticOut).
class AnimatedSection extends StatefulWidget {
  /// The widget to animate.
  final Widget child;

  /// Delay in milliseconds before the animation starts.
  final int delay;

  const AnimatedSection({
    Key? key,
    required this.child,
    required this.delay,
  }) : super(key: key);

  @override
  _AnimatedSectionState createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation for a gradual appearance.
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Scale animation for a subtle “pop” effect.
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Delays the start of the animation by [widget.delay].
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A page allowing the user to update their profile, including dynamic lists
/// for Experience, Education, Skills, and Contact Info. Each list is backed
/// by a Realtime Database structure in Firebase.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  /// A global key to help validate form fields before saving to Firebase.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Basic text controllers for single-value profile fields.
  final TextEditingController profilePictureController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController headlineController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();

  /// Lists to store experiences and education items.
  /// Each list element is a map of data fields.
  List<Map<String, dynamic>> _experienceList = [];
  List<Map<String, dynamic>> _educationList = [];

  /// List of skill strings. Strings are simpler than maps because
  /// skills are typically stored as plain text.
  List<String> _skills = [];

  /// Controller for adding new skills.
  final TextEditingController newSkillController = TextEditingController();

  /// Controllers for contact info.
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController githubController = TextEditingController();

  /// Flag to indicate background saving or loading processes.
  bool isLoading = false;

  /// Firebase Realtime Database reference and Auth instance.
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentProfileData();
  }

  /// Loads the user's current profile data from Firebase and populates controllers.
  /// This is triggered in [didChangeDependencies] so it refreshes if dependencies change.
  /// We also handle cases where 'experience' or 'education' might come back
  /// as a Map with numeric keys instead of a pure List.
  Future<void> _loadCurrentProfileData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child('users/${user.uid}').get();
      if (snapshot.exists && snapshot.value != null) {
        // Convert snapshot.value into a Map<String, dynamic> safely
        final rawData = snapshot.value as Map;
        final data = Map<String, dynamic>.from(rawData);

        setState(() {
          // Single-value fields
          profilePictureController.text = data['profilePictureUrl'] ?? '';
          fullNameController.text = data['fullName'] ?? '';
          jobTitleController.text = data['jobTitle'] ?? '';
          locationController.text = data['location'] ?? '';
          headlineController.text = data['headline'] ?? '';
          summaryController.text = data['summary'] ?? '';

          // Skills can typically be read directly as a List<String>
          if (data['skills'] is List) {
            _skills = List<String>.from(data['skills']);
          } else {
            _skills = [];
          }

          // Convert 'experience' to a List<Map<String, dynamic>> no matter if it’s a List or a Map
          final rawExperience = data['experience'];
          if (rawExperience is List) {
            _experienceList = rawExperience
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          } else if (rawExperience is Map) {
            _experienceList = rawExperience.values
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          } else {
            _experienceList = [];
          }

          // Convert 'education' similarly
          final rawEducation = data['education'];
          if (rawEducation is List) {
            _educationList = rawEducation
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          } else if (rawEducation is Map) {
            _educationList = rawEducation.values
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          } else {
            _educationList = [];
          }

          // Contact info is stored in a map or might be null
          if (data['contact'] is Map) {
            final contact = data['contact'] as Map;
            linkedinController.text = contact['linkedin'] ?? '';
            twitterController.text = contact['twitter'] ?? '';
            githubController.text = contact['github'] ?? '';
          }
        });
      }
    }
  }

  /// Saves the entire profile to Firebase under the user's node.
  /// [popPage] indicates whether the page should close after saving.
  Future<void> _saveProfile({bool popPage = false}) async {
    // Validate form fields first (Name, JobTitle, etc.).
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final user = _auth.currentUser;
    if (user != null) {
      final updatedData = {
        'profilePictureUrl': profilePictureController.text.trim(),
        'fullName': fullNameController.text.trim(),
        'jobTitle': jobTitleController.text.trim(),
        'location': locationController.text.trim(),
        'headline': headlineController.text.trim(),
        'summary': summaryController.text.trim(),
        'skills': _skills,
        'experience': _experienceList,
        'education': _educationList,
        'contact': {
          'linkedin': linkedinController.text.trim(),
          'twitter': twitterController.text.trim(),
          'github': githubController.text.trim(),
        },
      };
      try {
        // Write the entire data map to Firebase.
        await _dbRef.child('users/${user.uid}').set(updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Close the page if requested (e.g., final save).
        if (popPage) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  /// Opens a dialog to add a new experience item. The user fills out
  /// multiple fields. On "Add," the new entry is appended to _experienceList
  /// and saved to Firebase by calling [_saveProfile].
  Future<void> _showAddExperienceDialog() async {
    final jobTitleCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final companyLogoCtrl = TextEditingController();
    final startDateCtrl = TextEditingController();
    final endDateCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Experience'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: companyLogoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company Logo URL (optional)',
                  ),
                ),
                TextField(
                  controller: jobTitleCtrl,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                ),
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                TextField(
                  controller: startDateCtrl,
                  decoration: const InputDecoration(labelText: 'Start Date'),
                ),
                TextField(
                  controller: endDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'End Date (or "Present")',
                  ),
                ),
                TextField(
                  controller: descriptionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                setState(() {
                  _experienceList.add({
                    'companyLogoUrl': companyLogoCtrl.text.trim(),
                    'jobTitle': jobTitleCtrl.text.trim(),
                    'company': companyCtrl.text.trim(),
                    'startDate': startDateCtrl.text.trim(),
                    'endDate': endDateCtrl.text.trim(),
                    'description': descriptionCtrl.text.trim(),
                  });
                });

                // Save immediately to Firebase.
                _saveProfile();

                // Close only the dialog.
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Opens a dialog to edit an existing experience item at [index].
  /// The fields are prefilled with data from [exp]. On Save, it updates
  /// the list and calls [_saveProfile].
  Future<void> _showEditExperienceDialog(
    Map<String, dynamic> exp,
    int index,
  ) async {
    final jobTitleCtrl = TextEditingController(text: exp['jobTitle']);
    final companyCtrl = TextEditingController(text: exp['company']);
    final companyLogoCtrl = TextEditingController(text: exp['companyLogoUrl']);
    final startDateCtrl = TextEditingController(text: exp['startDate']);
    final endDateCtrl = TextEditingController(text: exp['endDate']);
    final descriptionCtrl = TextEditingController(text: exp['description']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Experience'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: companyLogoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company Logo URL (optional)',
                  ),
                ),
                TextField(
                  controller: jobTitleCtrl,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                ),
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                TextField(
                  controller: startDateCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Start Date'),
                ),
                TextField(
                  controller: endDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'End Date (or "Present")',
                  ),
                ),
                TextField(
                  controller: descriptionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                // Update the existing entry.
                setState(() {
                  _experienceList[index] = {
                    'companyLogoUrl': companyLogoCtrl.text.trim(),
                    'jobTitle': jobTitleCtrl.text.trim(),
                    'company': companyCtrl.text.trim(),
                    'startDate': startDateCtrl.text.trim(),
                    'endDate': endDateCtrl.text.trim(),
                    'description': descriptionCtrl.text.trim(),
                  };
                });

                // Persist changes to Firebase.
                _saveProfile();

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Opens a dialog to add a new education item.
  /// On “Add”, the new map is appended to _educationList and saved.
  Future<void> _showAddEducationDialog() async {
    final institutionLogoCtrl = TextEditingController();
    final degreeCtrl = TextEditingController();
    final institutionCtrl = TextEditingController();
    final datesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Education'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: institutionLogoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Institution Logo URL (optional)',
                  ),
                ),
                TextField(
                  controller: degreeCtrl,
                  decoration: const InputDecoration(labelText: 'Degree'),
                ),
                TextField(
                  controller: institutionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Institution'),
                ),
                TextField(
                  controller: datesCtrl,
                  decoration: const InputDecoration(labelText: 'Dates'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                setState(() {
                  _educationList.add({
                    'institutionLogoUrl':
                        institutionLogoCtrl.text.trim(),
                    'degree': degreeCtrl.text.trim(),
                    'institution': institutionCtrl.text.trim(),
                    'dates': datesCtrl.text.trim(),
                  });
                });
                _saveProfile();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Opens a dialog to edit an education item stored at [index].
  /// On "Save", it updates the item and writes it to Firebase.
  Future<void> _showEditEducationDialog(
    Map<String, dynamic> edu,
    int index,
  ) async {
    final institutionLogoCtrl =
        TextEditingController(text: edu['institutionLogoUrl']);
    final degreeCtrl = TextEditingController(text: edu['degree']);
    final institutionCtrl =
        TextEditingController(text: edu['institution']);
    final datesCtrl = TextEditingController(text: edu['dates']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Education'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: institutionLogoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Institution Logo URL (optional)',
                  ),
                ),
                TextField(
                  controller: degreeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Degree'),
                ),
                TextField(
                  controller: institutionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Institution'),
                ),
                TextField(
                  controller: datesCtrl,
                  decoration: const InputDecoration(labelText: 'Dates'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                // Update the list entry.
                setState(() {
                  _educationList[index] = {
                    'institutionLogoUrl':
                        institutionLogoCtrl.text.trim(),
                    'degree': degreeCtrl.text.trim(),
                    'institution': institutionCtrl.text.trim(),
                    'dates': datesCtrl.text.trim(),
                  };
                });
                // Save changes to Firebase.
                _saveProfile();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Adds a new skill by reading the user’s input from [newSkillController].
  /// If the field is non-empty, the skill is added to the list and saved.
  void _addSkill() {
    if (newSkillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(newSkillController.text.trim());
        newSkillController.clear();
      });
      _saveProfile();
    }
  }

  /// Opens a dialog to edit an existing [skill].
  /// On “Save,” the updated value replaces the old skill in the list.
  Future<void> _showEditSkillDialog(String skill, int index) async {
    final skillCtrl = TextEditingController(text: skill);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Skill'),
          content: TextField(
            controller: skillCtrl,
            decoration: const InputDecoration(labelText: 'Skill'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                setState(() {
                  _skills[index] = skillCtrl.text.trim();
                });
                _saveProfile();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a dialog of avatar assets. When the user selects one,
  /// it’s assigned to [profilePictureController.text] and saved to Firebase.
  Future<void> _showAvatarPickerDialog() async {
    final List<String> avatarAssets = [
      'assets/Avatars/avatar1.jpg',
      'assets/Avatars/avatar2.jpg',
      'assets/Avatars/avatar3.jpg',
      'assets/Avatars/avatar4.jpg',
      'assets/Avatars/avatar5.jpg',
    ];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select an Avatar"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              shrinkWrap: true,
              itemCount: avatarAssets.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      profilePictureController.text = avatarAssets[index];
                    });
                    _saveProfile();
                    Navigator.pop(context);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(avatarAssets[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose all controllers to free memory.
    profilePictureController.dispose();
    fullNameController.dispose();
    jobTitleController.dispose();
    locationController.dispose();
    headlineController.dispose();
    summaryController.dispose();
    newSkillController.dispose();
    linkedinController.dispose();
    twitterController.dispose();
    githubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Background gradient for the entire page, providing a more vibrant look.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFFFF9C4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: primaryColor,
              title: const Text('Edit Profile'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Profile Picture Section
                    AnimatedSection(
                      delay: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Picture',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    profilePictureController.text.isNotEmpty
                                        ? (profilePictureController.text
                                                .startsWith('assets/')
                                            ? AssetImage(
                                                profilePictureController.text)
                                            : NetworkImage(
                                                profilePictureController.text))
                                            as ImageProvider?
                                        : null,
                                backgroundColor: Colors.grey[200],
                                child: profilePictureController.text.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                ),
                                onPressed: _showAvatarPickerDialog,
                                child: const Text("Choose Avatar"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Personal Information Section
                    AnimatedSection(
                      delay: 400,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Full Name is required.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: jobTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Job Title *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Job Title is required.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Location is required.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: headlineController,
                            decoration: const InputDecoration(
                              labelText: 'Headline *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Headline is required.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: summaryController,
                            decoration: const InputDecoration(
                              labelText: 'Summary',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Experience Section
                    AnimatedSection(
                      delay: 600,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Experience',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children:
                                _experienceList.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final Map<String, dynamic> exp = entry.value;
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: exp['companyLogoUrl'] != null &&
                                            exp['companyLogoUrl'] != ''
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Image.network(
                                              exp['companyLogoUrl'],
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.business,
                                            color: Colors.grey),
                                  ),
                                  title: Text(exp['jobTitle'] ?? ''),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(exp['company'] ?? ''),
                                      Text(
                                        '${exp['startDate'] ?? ''} - ${exp['endDate'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _showEditExperienceDialog(exp, index);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            _experienceList.removeAt(index);
                                          });
                                          _saveProfile();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          TextButton(
                            onPressed: _showAddExperienceDialog,
                            child: const Text('Add Experience'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Education Section
                    AnimatedSection(
                      delay: 800,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Education',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children:
                                _educationList.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final Map<String, dynamic> edu = entry.value;
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: edu['institutionLogoUrl'] != null &&
                                            edu['institutionLogoUrl'] != ''
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              edu['institutionLogoUrl'],
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.school,
                                            color: Colors.grey),
                                  ),
                                  title: Text(edu['degree'] ?? ''),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(edu['institution'] ?? ''),
                                      Text(
                                        edu['dates'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _showEditEducationDialog(edu, index);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            _educationList.removeAt(index);
                                          });
                                          _saveProfile();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          TextButton(
                            onPressed: _showAddEducationDialog,
                            child: const Text('Add Education'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Skills Section
                    AnimatedSection(
                      delay: 1000,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skills',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_skills.length, (index) {
                              final String skill = _skills[index];
                              return GestureDetector(
                                onLongPress: () =>
                                    _showEditSkillDialog(skill, index),
                                child: Chip(
                                  label: Text(skill),
                                  backgroundColor: Colors.grey[200],
                                  onDeleted: () {
                                    setState(() {
                                      _skills.removeAt(index);
                                    });
                                    _saveProfile();
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: newSkillController,
                                  decoration: const InputDecoration(
                                    labelText: 'New Skill',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                ),
                                onPressed: _addSkill,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Contact Information Section
                    AnimatedSection(
                      delay: 1200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: linkedinController,
                            decoration: const InputDecoration(
                              labelText: 'LinkedIn URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: twitterController,
                            decoration: const InputDecoration(
                              labelText: 'Twitter URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: githubController,
                            decoration: const InputDecoration(
                              labelText: 'GitHub URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Final "Save Profile" Button
                    AnimatedSection(
                      delay: 1400,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                // Saves the profile and closes the page.
                                await _saveProfile(popPage: true);
                              },
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
