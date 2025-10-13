import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.launchSource});

  final ImageSource? launchSource; // optional immediate pick on open

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  Uint8List? _bytes;
  String? _fileName;
  String? _sourceLabel; // 'Camera' or 'Gallery'

  @override
  void initState() {
    super.initState();
    if (widget.launchSource != null) {
      // pick after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _pick(widget.launchSource!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: Text(_headerTitle()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF2F5F8),
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF5A5AF7), width: 2),
              ),
              child: _bytes == null
                  ? const Center(child: Text('Uploaded File Image Placeholder', style: TextStyle(color: Color(0xFF5A5AF7))))
                  : Image.memory(_bytes!, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _shadowButton(
                    dark: true,
                    child: ElevatedButton(
                      onPressed: _chooseSource,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                        elevation: 0,
                      ),
                      child: const Text('Upload/Take Photo'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _shadowButton(
                    child: ElevatedButton(
                      onPressed: _bytes == null ? null : _goAnalyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                        elevation: 0,
                      ),
                      child: const Text('Analyze'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _headerTitle() {
    if (_bytes == null) return '[If/Then/Else (2 Conditions...';
    final src = _sourceLabel == null ? '' : 'Image from $_sourceLabel · ';
    return '$src${_fileName ?? ''}'.trim();
  }

  Widget _shadowButton({required Widget child, bool dark = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _chooseSource() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); _pick(ImageSource.camera); }),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Upload from Gallery'), onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _bytes = bytes;
      _fileName = file.name;
      _sourceLabel = source == ImageSource.camera ? 'Camera' : 'Gallery';
    });
  }

  void _goAnalyze() {
    Navigator.of(context).pushNamed('/processing');
  }
}


