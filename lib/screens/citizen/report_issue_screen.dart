import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/dark_mode_helper.dart';

class ReportIssueScreen extends StatefulWidget {
  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  LatLng? _selectedLocation;
  XFile? _issueImage;

  @override
  Widget build(BuildContext context) {
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(title: Text('Report Issue')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Issue Description'),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  setState(() => _issueImage = image);
                },
                child: Text(
                  _issueImage == null ? 'Upload Photo' : 'Photo Selected',
                ),
              ),
              SizedBox(height: 20),
              Container(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(30.0444, 31.2357), // Cairo
                    zoom: 13,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_pin,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitIssue,
                child: Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitIssue() async {
    if (_descriptionController.text.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      String? imageUrl;
      if (_issueImage != null) {
        final ref = _storage.ref(
          'issues/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(File(_issueImage!.path));
        imageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('issues').add({
        'description': _descriptionController.text,
        'location': GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        ),
        'imageUrl': imageUrl,
        'status': 'reported',
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Issue reported successfully')));

      _descriptionController.clear();
      setState(() {
        _issueImage = null;
        _selectedLocation = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to report issue: $e')));
    }
  }
}
