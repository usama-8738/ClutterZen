import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'theme.dart';
import 'screens/results/results_screen.dart';
import 'services/vision_service.dart';
import 'routes.dart';
import 'screens/app/photo_upload_screen.dart';

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
      routes: {
        ...AppRoutes.routes,
        '/home': (context) => const HomePage(),
      },
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
      const CaptureScreen(),
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
        // Greeting + small subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Let\'s declutter with AI today', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            IconButton(onPressed: () => Navigator.of(context).pushNamed('/notification-settings'), icon: const Icon(Icons.notifications_none)),
          ],
        ),
        const SizedBox(height: 12),
        // Search bar
        const _SearchBar(),
        const SizedBox(height: 16),
        // Promo carousel (covers home-screen and home-screen-2 hero variants)
        const _PromoCarousel(),
        const SizedBox(height: 16),
        // Quick actions
        const _QuickActionsRow(),
        const SizedBox(height: 16),
        // Categories chips
        const _SectionTitle('Categories'),
        const SizedBox(height: 8),
        const _CategoryChips(),
        const SizedBox(height: 16),
        // Recent analyses
        const _SectionTitle('Recent Analyses'),
        const SizedBox(height: 8),
        const _RecentAnalysesList(),
        const SizedBox(height: 16),
        // Tips/CTA
        const _TipsCard(),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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

class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search rooms, items, or tips',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();
  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PromoCard(
        title: 'Declutter in minutes',
        subtitle: 'Scan your space and get an AI plan',
        buttonText: 'Start Scan',
        onPressed: () => _goUpload(context),
        color: Theme.of(context).colorScheme.primary,
      ),
      _PromoCard(
        title: 'Track your progress',
        subtitle: 'Before/after photos and tips',
        buttonText: 'View Progress',
        onPressed: () => Navigator.of(context).pushNamed('/history'),
        color: Theme.of(context).colorScheme.secondary,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(right: 8), child: pages[i]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (i) => _Dot(active: i == _index)),
        )
      ],
    );
  }

  void _goUpload(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    state?.setState(() => state._index = 2);
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.title, required this.subtitle, required this.buttonText, required this.onPressed, required this.color});
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Theme.of(context).colorScheme.primary : Colors.grey[400],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickActionButton(icon: Icons.camera_alt_outlined, label: 'Capture', onTap: () => _goUpload(context))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionButton(icon: Icons.photo_library_outlined, label: 'Gallery', onTap: () => _goUpload(context))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionButton(icon: Icons.analytics_outlined, label: 'Analyze', onTap: () => _goUpload(context))),
      ],
    );
  }
  void _goUpload(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    state?.setState(() => state._index = 2);
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();
  @override
  Widget build(BuildContext context) {
    final cats = const ['Bedroom', 'Kitchen', 'Office', 'Closet', 'Garage', 'Living'];
    return Wrap(
      spacing: 8,
      runSpacing: -8,
      children: cats.map((c) => ActionChip(label: Text(c), onPressed: () => Navigator.of(context).pushNamed('/categories'))).toList(),
    );
  }
}

class _RecentAnalysesList extends StatelessWidget {
  const _RecentAnalysesList();
  @override
  Widget build(BuildContext context) {
    final items = const [
      {'title': 'Bedroom scan', 'subtitle': '12 items detected • 6 tips'},
      {'title': 'Kitchen scan', 'subtitle': '8 items detected • 4 tips'},
    ];
    return Column(
      children: [
        for (final i in items)
          Card(
            child: ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(i['title']!),
              subtitle: Text(i['subtitle']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/history'),
            ),
          ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Tips & Resources', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Group similar items together'),
          Text('• Label bins and shelves'),
          Text('• Clear surfaces first'),
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
