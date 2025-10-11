import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/vision_service.dart';
import '../results/results_screen.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final TextEditingController _controller = TextEditingController(text: 'https://storage.googleapis.com/vision-api-test/shanghai.jpeg');
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Upload')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('From URL', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Image URL')),
          const SizedBox(height: 8),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _analyzeUrl,
            child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Analyze URL'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('From Camera/Gallery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Camera'))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeUrl() async {
    final url = _controller.text.trim();
    if (!url.startsWith('http')) {
      setState(() => _error = 'Enter a valid image URL');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      const visionApiKey = String.fromEnvironment('VISION_API_KEY', defaultValue: '');
      if (visionApiKey.isEmpty) { setState(() => _error = 'Missing Vision API key (VISION_API_KEY).'); setState(() => _loading = false); return; }
      final service = VisionService(apiKey: visionApiKey);
      final analysis = await service.analyzeImageUrl(url);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen(image: NetworkImage(url), analysis: analysis)));
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() { _loading = true; _error = null; });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, maxWidth: 1600);
      if (file == null) { setState(() => _loading = false); return; }
      final bytes = await file.readAsBytes();
      const visionApiKey = String.fromEnvironment('VISION_API_KEY', defaultValue: '');
      if (visionApiKey.isEmpty) { setState(() => _error = 'Missing Vision API key (VISION_API_KEY).'); setState(() => _loading = false); return; }
      final service = VisionService(apiKey: visionApiKey);
      final analysis = await service.analyzeImageBytes(bytes);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen(image: MemoryImage(bytes), analysis: analysis)));
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}


