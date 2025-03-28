import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffAvailabilityPage extends StatefulWidget {
  @override
  _StaffAvailabilityPageState createState() => _StaffAvailabilityPageState();
}

class _StaffAvailabilityPageState extends State<StaffAvailabilityPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // The selected availability status
  String _selectedStatus = 'Available';

  // A reference to the Firestore collection (you can name it whatever you like)
  final CollectionReference staffAvailabilityCollection =
  FirebaseFirestore.instance.collection('staffAvailability');

  bool isLoading = false;

  // We’ll load the current user’s availability when the widget initializes
  @override
  void initState() {
    super.initState();
    _loadCurrentAvailability();
  }

  // This method fetches the current user's availability from Firestore
  Future<void> _loadCurrentAvailability() async {
    if (currentUser == null) return; // If not logged in, do nothing
    setState(() {
      isLoading = true;
    });

    try {
      DocumentSnapshot doc = await staffAvailabilityCollection
          .doc(currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('status')) {
          _selectedStatus = data['status'] as String;
        }
      }
    } catch (e) {
      print('Error loading availability: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // This method updates the current user's availability in Firestore
  Future<void> _updateAvailability() async {
    if (currentUser == null) return; // If not logged in, do nothing

    setState(() {
      isLoading = true;
    });

    try {
      await staffAvailabilityCollection.doc(currentUser!.uid).set({
        'status': _selectedStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Availability updated to $_selectedStatus')),
      );
    } catch (e) {
      print('Error updating availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple list of possible statuses
    final List<String> statuses = ['Available', 'Busy', 'Out of Office'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Availability'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Set Your Availability',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: statuses.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Availability Status',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateAvailability,
              child: Text('Update Availability'),
            ),
            SizedBox(height: 20),
            // Display the currently selected status for clarity
            Text(
              'Current Status: $_selectedStatus',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}