import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../app_firebase.dart';
import '../../services/user_service.dart';
import 'package:image_picker/image_picker.dart';

import '../../backend/registry.dart';
import '../../models/vision_models.dart';
import '../results/results_screen.dart';
import 'processing_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _loading = false;
  XFile? _image;

  @override
  Widget build(BuildContext context) {
    final uid = AppFirebase.auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scan'),
      ),
      body: uid == null
          ? const Center(child: Text('Please sign in to continue.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: AppFirebase.firestore
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final credits =
                    snapshot.data?.data()?['scanCredits'] as int? ?? 0;
                final hasCredits = credits > 0;

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _image == null
                            ? const Text('Uploaded File Image Placeholder')
                            : Image.file(File(_image!.path)),
                      ),
                    ),
                    if (!hasCredits)
                      Container(
                        color: Colors.red.withAlpha(26),
                        padding: const EdgeInsets.all(12),
                        child: const Text(
                          'You are out of scan credits. Please upgrade your plan to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _loading ? null : _showImageSourceDialog,
                              child: const Text('Upload/Take Photo'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _image == null || _loading || !hasCredits
                                      ? null
                                      : () => _analyze(uid, credits),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Analyze'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
    if (source != null) {
      _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await ImagePicker()
        .pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (img != null) {
      setState(() => _image = img);
    }
  }

  Future<void> _analyze(String uid, int availableCredits) async {
    if (_image == null) return;
    setState(() => _loading = true);
    final scaffold = ScaffoldMessenger.of(context);
    bool creditReserved = false;
    try {
      if (availableCredits <= 0) {
        scaffold.showSnackBar(
            const SnackBar(content: Text('You have no scan credits left.')));
        return;
      }
      final reserved = await UserService.consumeCredit(uid);
      if (!reserved) {
        scaffold.showSnackBar(
            const SnackBar(content: Text('Unable to reserve a scan credit.')));
        return;
      }
      creditReserved = true;
      final img = _image!;
      final bytes = await img.readAsBytes();
      if (!mounted) {
        await UserService.refundCredit(uid);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            background: MemoryImage(bytes),
            onReady: (context) async {
              try {
                final now = DateTime.now();
                final path =
                    'uploads/$uid/${now.toIso8601String()}-${img.name}';
                final imageUrl = await Registry.storage.uploadBytes(
                    path: path, data: bytes, contentType: img.mimeType);
                final VisionAnalysis analysis =
                    await Registry.vision.analyzeImageUrl(imageUrl);
                String organizedUrl = imageUrl;
                try {
                  organizedUrl = await Registry.replicate
                      .generateOrganizedImage(imageUrl: imageUrl);
                } catch (replicateError) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Analysis ready, but organized preview failed: $replicateError')));
                  }
                }
                await Registry.analysis.create(
                  uid: uid,
                  title: 'Scan from ${now.toLocal()}',
                  imageUrl: imageUrl,
                  organizedImageUrl: organizedUrl,
                  analysis: analysis,
                );
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ResultsScreen(
                        image: NetworkImage(imageUrl),
                        analysis: analysis,
                        organizedUrl: organizedUrl,
                      ),
                    ),
                  );
                }
              } catch (error) {
                await UserService.refundCredit(uid);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              }
            },
          ),
        ),
      );
      creditReserved = false;
    } catch (e) {
      if (creditReserved) {
        await UserService.refundCredit(uid);
      }
      scaffold.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
