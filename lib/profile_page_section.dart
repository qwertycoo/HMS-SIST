import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Edit_profile_Page.dart';
import 'ChatMessage.dart';  // Add this import to access the ChatScreen

/// Main brand color.
const Color primaryColor = Color(0xFF1DA1F2);

/// A helper widget that applies both fade and scale transitions.
class AnimatedSection extends StatefulWidget {
  final Widget child;
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
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

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

/// Displays the user's profile. If a [uid] is provided, the profile data for
/// that uid is fetched; otherwise, the current user's profile is shown.
class ProfilePage extends StatefulWidget {
  final String? uid;
  const ProfilePage({Key? key, this.uid}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  /// Fetches profile data from Realtime Database. Uses [widget.uid] if provided,
  /// otherwise loads the current user's data.
  Future<void> _fetchProfileData() async {
    final uid = widget.uid ?? _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _dbRef.child('users/$uid').get();
      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value as Map;
        final data = Map<String, dynamic>.from(rawData);

        // Convert 'experience' to List<Map<String, dynamic>>
        final rawExperience = data['experience'];
        if (rawExperience is List) {
          data['experience'] = rawExperience
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else if (rawExperience is Map) {
          data['experience'] = rawExperience.values
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else {
          data['experience'] = [];
        }

        // Convert 'education' similarly
        final rawEducation = data['education'];
        if (rawEducation is List) {
          data['education'] = rawEducation
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else if (rawEducation is Map) {
          data['education'] = rawEducation.values
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else {
          data['education'] = [];
        }

        setState(() {
          profileData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  /// Saves updated profile data.
  Future<void> _saveProfileData() async {
    final user = _auth.currentUser;
    if (user == null || profileData == null) return;

    try {
      await _dbRef.child('users/${user.uid}').set(profileData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _showEditExperienceDialog(
      Map<String, dynamic> exp, int index) async {
    final TextEditingController companyLogoCtrl =
        TextEditingController(text: exp['companyLogoUrl']);
    final TextEditingController jobTitleCtrl =
        TextEditingController(text: exp['jobTitle']);
    final TextEditingController companyCtrl =
        TextEditingController(text: exp['company']);
    final TextEditingController startDateCtrl =
        TextEditingController(text: exp['startDate']);
    final TextEditingController endDateCtrl =
        TextEditingController(text: exp['endDate']);
    final TextEditingController descriptionCtrl =
        TextEditingController(text: exp['description']);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Experience'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: companyLogoCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Company Logo URL (optional)'),
                ),
                TextField(
                  controller: jobTitleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Job Title'),
                ),
                TextField(
                  controller: companyCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Company'),
                ),
                TextField(
                  controller: startDateCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Start Date'),
                ),
                TextField(
                  controller: endDateCtrl,
                  decoration: const InputDecoration(
                      labelText: 'End Date (or "Present")'),
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
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor),
              onPressed: () {
                final experiences =
                    (profileData?['experience'] as List<Map<String, dynamic>>);
                experiences[index] = {
                  'companyLogoUrl': companyLogoCtrl.text.trim(),
                  'jobTitle': jobTitleCtrl.text.trim(),
                  'company': companyCtrl.text.trim(),
                  'startDate': startDateCtrl.text.trim(),
                  'endDate': endDateCtrl.text.trim(),
                  'description': descriptionCtrl.text.trim(),
                };

                setState(() {
                  profileData?['experience'] = experiences;
                });

                _saveProfileData();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeExperience(int index) {
    if (profileData == null) return;
    final experiences =
        (profileData!['experience'] as List<Map<String, dynamic>>);
    experiences.removeAt(index);
    setState(() {
      profileData!['experience'] = experiences;
    });
    _saveProfileData();
  }

  Future<void> _showEditEducationDialog(
      Map<String, dynamic> edu, int index) async {
    final TextEditingController institutionLogoCtrl =
        TextEditingController(text: edu['institutionLogoUrl']);
    final TextEditingController degreeCtrl =
        TextEditingController(text: edu['degree']);
    final TextEditingController institutionCtrl =
        TextEditingController(text: edu['institution']);
    final TextEditingController datesCtrl =
        TextEditingController(text: edu['dates']);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Education'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: institutionLogoCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Institution Logo URL (optional)'),
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
                  decoration:
                      const InputDecoration(labelText: 'Dates'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor),
              onPressed: () {
                final educations =
                    (profileData!['education'] as List<Map<String, dynamic>>);
                educations[index] = {
                  'institutionLogoUrl':
                      institutionLogoCtrl.text.trim(),
                  'degree': degreeCtrl.text.trim(),
                  'institution': institutionCtrl.text.trim(),
                  'dates': datesCtrl.text.trim(),
                };

                setState(() {
                  profileData!['education'] = educations;
                });

                _saveProfileData();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeEducation(int index) {
    if (profileData == null) return;
    final educations =
        (profileData!['education'] as List<Map<String, dynamic>>);
    educations.removeAt(index);
    setState(() {
      profileData!['education'] = educations;
    });
    _saveProfileData();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String? profilePictureUrl =
        profileData?['profilePictureUrl'];
    ImageProvider? avatarProvider;
    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      avatarProvider = profilePictureUrl.startsWith('assets/')
          ? AssetImage(profilePictureUrl)
          : NetworkImage(profilePictureUrl) as ImageProvider;
    }
    return Row(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: avatarProvider,
          backgroundColor: Colors.grey[200],
          child: avatarProvider == null
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profileData?['fullName'] ?? 'Full Name',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                profileData?['jobTitle'] ?? 'Job Title',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    profileData?['location'] ?? 'Location',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadlineAndSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profileData?['headline'] ?? 'Professional Headline',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          profileData?['summary'] ?? 'Summary goes here...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    final List<dynamic> experiences =
        (profileData?['experience'] is List)
            ? profileData!['experience']
            : [];
    if (experiences.isEmpty) {
      return const Text('No experience added.');
    }
    return Column(
      children: experiences.asMap().entries.map((entry) {
        final int index = entry.key;
        final exp = entry.value as Map<String, dynamic>;
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: (exp['companyLogoUrl'] != null &&
                          exp['companyLogoUrl'].isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            exp['companyLogoUrl'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.business,
                          size: 30, color: Colors.grey),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp['jobTitle'] ?? 'Job Title',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        exp['company'] ?? 'Company Name',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exp['startDate'] ?? ''} - ${exp['endDate'] ?? 'Present'}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exp['description'] ?? 'Description',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEditExperienceDialog(exp, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeExperience(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEducationSection() {
    final List<dynamic> educations =
        (profileData?['education'] is List)
            ? profileData!['education']
            : [];
    if (educations.isEmpty) {
      return const Text('No education added.');
    }
    return Column(
      children: educations.asMap().entries.map((entry) {
        final int index = entry.key;
        final edu = entry.value as Map<String, dynamic>;
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: (edu['institutionLogoUrl'] != null &&
                          edu['institutionLogoUrl'].isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            edu['institutionLogoUrl'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.school, color: Colors.grey),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        edu['degree'] ?? 'Degree',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        edu['institution'] ?? 'Institution',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        edu['dates'] ?? 'Dates attended',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditEducationDialog(edu, entry.key),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeEducation(entry.key),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillsSection() {
    final List<dynamic> skills =
        (profileData?['skills'] is List)
            ? profileData!['skills']
            : [];
    if (skills.isEmpty) return const Text('No skills added.');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Chip(
          label: Text(skill.toString()),
          backgroundColor: Colors.grey[200],
        );
      }).toList(),
    );
  }

  Widget _buildContactInfoSection() {
    final contact =
        (profileData?['contact'] is Map)
            ? profileData!['contact'] as Map
            : {};
    if (contact.isEmpty)
      return const Text('No contact information provided.');
    return Row(
      children: [
        if (contact['linkedin'] != null &&
            (contact['linkedin'] as String).isNotEmpty)
          IconButton(
            icon:
                const Icon(Icons.link, color: primaryColor),
            tooltip: 'LinkedIn',
            onPressed: () {
              // Implement URL launching here.
            },
          ),
        if (contact['twitter'] != null &&
            (contact['twitter'] as String).isNotEmpty)
          IconButton(
            icon: const Icon(Icons.alternate_email,
                color: primaryColor),
            tooltip: 'Twitter',
            onPressed: () {
              // Implement URL launching here.
            },
          ),
        if (contact['github'] != null &&
            (contact['github'] as String).isNotEmpty)
          IconButton(
            icon:
                const Icon(Icons.code, color: primaryColor),
            tooltip: 'GitHub',
            onPressed: () {
              // Implement URL launching here.
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Using a gradient background.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFFFF9C4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator())
              : profileData == null
                  ? const Center(
                      child: Text('No profile data available.'))
                  : CustomScrollView(
                      slivers: [
                        // In the build method of _ProfilePageState, update the SliverAppBar actions:

                        SliverAppBar(
                          backgroundColor: primaryColor,
                          pinned: true,
                          expandedHeight: 200,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(profileData?['fullName'] ?? 'Profile'),
                            background: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildProfileHeader(),
                            ),
                          ),
                          actions: [
                            // Only show chat button if this is NOT the current user's profile
                            if (widget.uid != null && widget.uid != _auth.currentUser?.uid)
                              IconButton(
                                icon: const Icon(Icons.chat),
                                tooltip: 'Chat with this user',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(receiverId: widget.uid!),
                                    ),
                                  );
                                },
                              ),

                            IconButton(
                              icon: const Icon(Icons.logout),
                              tooltip: 'Logout',
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                            ),

                            // Only show edit button if this is the current user's profile.
                            if (widget.uid == null)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Profile (Separate Page)',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfilePage(),
                                    ),
                                  ).then((_) => _fetchProfileData());
                                },
                              ),
                          ],
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSection(
                                      delay: 200,
                                      child: _buildHeadlineAndSummary(),
                                    ),
                                    const Divider(
                                        thickness: 1,
                                        height: 30),
                                    AnimatedSection(
                                      delay: 400,
                                      child: _buildSectionTitle(
                                          'Experience'),
                                    ),
                                    AnimatedSection(
                                      delay: 500,
                                      child: _buildExperienceSection(),
                                    ),
                                    const Divider(
                                        thickness: 1,
                                        height: 30),
                                    AnimatedSection(
                                      delay: 600,
                                      child: _buildSectionTitle(
                                          'Education'),
                                    ),
                                    AnimatedSection(
                                      delay: 700,
                                      child: _buildEducationSection(),
                                    ),
                                    const Divider(
                                        thickness: 1,
                                        height: 30),
                                    AnimatedSection(
                                      delay: 800,
                                      child: _buildSectionTitle(
                                          'Skills & Endorsements'),
                                    ),
                                    AnimatedSection(
                                      delay: 900,
                                      child: _buildSkillsSection(),
                                    ),
                                    const Divider(
                                        thickness: 1,
                                        height: 30),
                                    AnimatedSection(
                                      delay: 1000,
                                      child: _buildSectionTitle(
                                          'Contact Information'),
                                    ),
                                    AnimatedSection(
                                      delay: 1100,
                                      child: _buildContactInfoSection(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
