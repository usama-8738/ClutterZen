import 'package:flutter/material.dart';
import '../../services/vision_service.dart';
import '../results/results_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clutter Zen')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Welcome',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Declutter with AI: scan, organize, and track progress.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const _HomeShell()),
                );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _UploadPage(),
      const _AnalysisPage(),
      const _TasksPage(),
      const _ProgressPage(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.timeline_outlined), label: 'Progress'),
        ],
      ),
    );
  }
}

class _UploadPage extends StatelessWidget {
  const _UploadPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paste an image URL to analyze with Google Vision API'),
            const SizedBox(height: 8),
            _AnalyzeForm(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Or choose a photo:'),
            const SizedBox(height: 8),
            _PickAndAnalyze(),
            const SizedBox(height: 16),
            const Text('Upload to Firebase Storage (uses current user):'),
            const SizedBox(height: 8),
            _UploadToStorage(),
          ],
        ),
      ),
    );
  }
}

class _UploadToStorage extends StatefulWidget {
  const _UploadToStorage();

  @override
  State<_UploadToStorage> createState() => _UploadToStorageState();
}

class _UploadToStorageState extends State<_UploadToStorage> {
  bool _loading = false;
  String? _result;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Uploaded URL:\n$_result'),
          ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _pickAndUpload,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Pick & Upload'),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (file == null) { setState(() => _loading = false); return; }
      final bytes = await file.readAsBytes();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) { setState(() => _error = 'Sign in first.'); setState(() => _loading = false); return; }

      final storage = StorageService(FirebaseStorage.instance);
      final path = 'users/$uid/uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await storage.uploadBytes(path: path, data: bytes, contentType: 'image/jpeg');
      setState(() => _result = url);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _AnalysisPage extends StatelessWidget {
  const _AnalysisPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: const Center(child: Text('AI results and overlays')),
    );
  }
}

class _TasksPage extends StatelessWidget {
  const _TasksPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: const Center(child: Text('Step-by-step instructions')),
    );
  }
}

class _AnalyzeForm extends StatefulWidget {
  const _AnalyzeForm();

  @override
  State<_AnalyzeForm> createState() => _AnalyzeFormState();
}

class _AnalyzeFormState extends State<_AnalyzeForm> {
  final TextEditingController _controller = TextEditingController(text: 'https://storage.googleapis.com/vision-api-test/shanghai.jpeg');
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'https://.../image.jpg',
            labelText: 'Image URL',
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: _loading ? null : _onAnalyze,
          child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Analyze'),
        ),
      ],
    );
  }

  Future<void> _onAnalyze() async {
    final url = _controller.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      setState(() => _error = 'Enter a valid image URL');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Use Env config; if missing, allow placeholder flow
      const visionApiKey = String.fromEnvironment('VISION_API_KEY', defaultValue: '');
      if (visionApiKey.isEmpty) {
        setState(() => _error = 'Missing Vision API key (VISION_API_KEY).');
        setState(() => _loading = false);
        return;
      }
      final service = VisionService(apiKey: visionApiKey);
      final analysis = await service.analyzeImageUrl(url);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(image: NetworkImage(url), analysis: analysis),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PickAndAnalyze extends StatefulWidget {
  const _PickAndAnalyze();

  @override
  State<_PickAndAnalyze> createState() => _PickAndAnalyzeState();
}

class _PickAndAnalyzeState extends State<_PickAndAnalyze> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, maxWidth: 1600);
      if (file == null) {
        setState(() => _loading = false);
        return;
      }
      final bytes = await file.readAsBytes();
      const visionApiKey = String.fromEnvironment('VISION_API_KEY', defaultValue: '');
      if (visionApiKey.isEmpty) {
        setState(() => _error = 'Missing Vision API key (VISION_API_KEY).');
        setState(() => _loading = false);
        return;
      }
      final service = VisionService(apiKey: visionApiKey);
      final analysis = await service.analyzeImageBytes(bytes);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(image: MemoryImage(bytes), analysis: analysis),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const Center(child: Text('Before/After and history')),
    );
  }
}


