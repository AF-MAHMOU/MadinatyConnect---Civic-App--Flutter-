import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportIssueScreen extends StatefulWidget {
  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _mapController = MapController();

  // Madinaty coordinates (30° 5' 47.9580'' N, 31° 39' 45.1188'' E)
  final LatLng _madinatyCoordinates = LatLng(30.096655, 31.662533);
  LatLng? _selectedLocation;
  XFile? _issueImage;

  @override
  void initState() {
    super.initState();
    // Set Madinaty as default selected location
    _selectedLocation = _madinatyCoordinates;
    // Center map on Madinaty after a small delay to ensure map is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_madinatyCoordinates, 15); // Higher zoom level for better precision
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Issue')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Issue Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                setState(() => _issueImage = image);
              },
              icon: Icon(Icons.photo_library),
              label: Text(_issueImage == null ? 'Upload Photo' : 'Photo Selected'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _madinatyCoordinates, // Default to Madinaty
                    zoom: 15, // Higher zoom level for better precision
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.madinatyconnect',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation ?? _madinatyCoordinates,
                          child: Icon(
                            Icons.location_pin,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitIssue,
              icon: Icon(Icons.send),
              label: Text('Submit Report'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitIssue() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login to report issues')),
        );
        return;
      }

      String? imageUrl;
      if (_issueImage != null) {
        final ref = _storage.ref('issues/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(_issueImage!.path));
        imageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('issues').add({
        'description': _descriptionController.text,
        'location': GeoPoint(
          _selectedLocation?.latitude ?? _madinatyCoordinates.latitude,
          _selectedLocation?.longitude ?? _madinatyCoordinates.longitude,
        ),
        'imageUrl': imageUrl,
        'status': 'pending',
        'creatorId': userId,
         'createdAt': FieldValue.serverTimestamp(), // Use createdAt instead of timestamp
    'timestamp': FieldValue.serverTimestamp(), // Keep for backward compatibility
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Issue reported successfully')),
      );

      _descriptionController.clear();
      setState(() {
        _issueImage = null;
        // Reset to Madinaty coordinates after submission
        _selectedLocation = _madinatyCoordinates;
        _mapController.move(_madinatyCoordinates, 15);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report issue: $e')),
      );
    }
  }
}