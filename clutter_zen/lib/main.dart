import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'theme.dart';
import 'screens/results/results_screen.dart';
import 'services/vision_service.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet; continue without blocking dev flow.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clutter Zen',
      theme: buildAppTheme(),
      routes: AppRoutes.routes,
      initialRoute: '/splash',
      home: const SizedBox.shrink(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const _CategoriesTab(),
      const _UploadTab(),
      const _TasksTab(),
      const _ProgressTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Clutter Zen')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.timeline_outlined), label: 'Progress'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Scan a room or pick a category to get started.'),
        const SizedBox(height: 16),
        _QuickActions(),
        const SizedBox(height: 16),
        Text('Rooms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _CategoriesGrid(compact: true),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _goUpload(context),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Capture'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _goUpload(context),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('From Gallery'),
          ),
        ),
      ],
    );
  }

  void _goUpload(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    state?.setState(() => state._index = 2);
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Choose a category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const _CategoriesGrid(compact: false),
      ],
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.compact});

  final bool compact;

  static const items = [
    {'title': 'Bedroom', 'icon': Icons.bed_outlined},
    {'title': 'Kitchen', 'icon': Icons.kitchen_outlined},
    {'title': 'Office', 'icon': Icons.desktop_windows_outlined},
    {'title': 'Closet', 'icon': Icons.checkroom_outlined},
    {'title': 'Garage', 'icon': Icons.garage_outlined},
    {'title': 'Living Room', 'icon': Icons.weekend_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: compact ? 3 : 2,
      childAspectRatio: compact ? 0.8 : 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final item in items)
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _CategoryScreen(title: item['title'] as String)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, size: compact ? 28 : 36, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(item['title'] as String, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryScreen extends StatelessWidget {
  const _CategoryScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Group similar items',
      'Use bins and labels',
      'Clear surfaces',
      'Donate unused items',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Getting started', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final s in suggestions)
            ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: Text(s)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Capture this room'),
          ),
        ],
      ),
    );
  }
}

class _UploadTab extends StatefulWidget {
  const _UploadTab();

  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  final TextEditingController _controller = TextEditingController(text: 'https://storage.googleapis.com/vision-api-test/shanghai.jpeg');
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Analyze from URL', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://.../image.jpg')),
        const SizedBox(height: 8),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _loading ? null : _analyzeUrl, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Analyze URL')),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text('Analyze from Camera/Gallery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Camera'))),
          ],
        ),
      ],
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

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Sort clothes by type')), 
        ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Label bins and drawers')),
        ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Clear desk surface')),
      ],
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(leading: Icon(Icons.photo_library_outlined), title: Text('Before/after - Bedroom')), 
        ListTile(leading: Icon(Icons.photo_library_outlined), title: Text('Before/after - Kitchen')),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
