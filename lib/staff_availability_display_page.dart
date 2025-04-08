import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import the update page where staff edit their availability:
import 'staff_availability_page.dart';

class StaffAvailabilityDisplayPage extends StatelessWidget {
  // Reference to the Firestore collection.
  final CollectionReference staffAvailabilityCollection =
  FirebaseFirestore.instance.collection('staffAvailability');

  // The defined staff credentials.
  final String staffEmail = 'chniwla@outlook.cardiffmet.ac.uk';
  final String staffUID = 'wrbjbiFT92c0dKmxczDAxMdYsk92';

  // Function to handle the "Update Your Status" button press.
  void _handleUpdateStatus(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null &&
        currentUser.email == staffEmail &&
        currentUser.uid == staffUID) {
      // Navigate to the update page.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StaffAvailabilityPage()),
      );
    } else {
      // Show error message if the user is not the defined staff.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("this option is only available for staffs al3chiwr")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Availability'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: staffAvailabilityCollection
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching data: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('No staff availability data found.'));
          }
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 80), // Ensure button is not overlapped.
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'Unknown';
              final String status = data['status'] ?? 'Unknown Status';
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(name),
                  subtitle: Text('Status: $status'),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        height: 80,
        child: ElevatedButton(
          onPressed: () => _handleUpdateStatus(context),
          child: Text(
            'Update Your Status',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}