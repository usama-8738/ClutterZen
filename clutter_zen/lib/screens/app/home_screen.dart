import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vision_models.dart';
import '../results/results_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        SizedBox(height: 8),
        _TopBar(),
        _TopGradientBar(),
        SizedBox(height: 12),
        _GreetingRow(),
        SizedBox(height: 12),
        _CenterLogo(),
        SizedBox(height: 12),
        _TitleText(),
        SizedBox(height: 8),
        _PrimaryActions(),
        SizedBox(height: 16),
        _SectionHeader('Recent Categories'),
        SizedBox(height: 8),
        _RecentCategories(),
        SizedBox(height: 16),
        _SectionHeader('Recent Scans'),
        SizedBox(height: 8),
        _RecentScans(),
        SizedBox(height: 16),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        const Icon(Icons.auto_awesome, size: 24),
        if (uid != null)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snap) {
              final credits = snap.data?.data()?['scanCredits']?.toString() ?? '0';
              return Row(children: [const Icon(Icons.camera_alt_outlined), const SizedBox(width: 4), Text(credits)]);
            },
          ),
      ],
    );
  }
}

class _TopGradientBar extends StatelessWidget {
  const _TopGradientBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF28A9FF), Color(0xFF48E58B)]),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _DisplayName(),
        IconButton(onPressed: () => Navigator.of(context).pushNamed('/settings'), icon: const Icon(Icons.settings)),
      ],
    );
  }
}

class _DisplayName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final name = snap.data?.displayName ?? '[Display Name]';
        return Text(name, style: Theme.of(context).textTheme.titleMedium);
      },
    );
  }
}

class _CenterLogo extends StatelessWidget {
  const _CenterLogo();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Declutter Anything!',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShadowButton(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/photo-upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
            ),
            child: const Text('Take Photo'),
          ),
        ),
        const SizedBox(height: 12),
        _ShadowButton(
          dark: true,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/photo-upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
            ),
            child: const Text('Upload from Gallery'),
          ),
        ),
      ],
    );
  }
}

class _ShadowButton extends StatelessWidget {
  const _ShadowButton({required this.child, this.dark = false});
  final Widget child;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Colors.grey).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      );
}

class _RecentCategories extends StatelessWidget {
  const _RecentCategories();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }
    final query = FirebaseFirestore.instance
        .collection('analyses')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 170, child: Center(child: CircularProgressIndicator()));
        final docs = snap.data!.docs;
        // Derive categories list from analyses' categories fields
        final Map<String, String> catToImage = {};
        for (final d in docs) {
          final img = d.data()['imageUrl'] as String?;
          final cats = (d.data()['categories'] as List?)?.cast<String>() ?? const <String>[];
          for (final c in cats) {
            catToImage.putIfAbsent(c, () => img ?? '');
          }
          if (catToImage.length >= 10) break;
        }
        final items = catToImage.entries.take(10).toList();
        return SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final label = items[i].key;
              final img = items[i].value;
              return Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        child: img.isNotEmpty ? Image.network(img, fit: BoxFit.cover) : Container(color: Colors.grey[300]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RecentScans extends StatelessWidget {
  const _RecentScans();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final query = FirebaseFirestore.instance
        .collection('analyses')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(10);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return Column(
          children: [
            for (final d in docs)
              Card(
                child: ListTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: (d.data()['imageUrl'] as String?)?.isNotEmpty == true
                      ? Image.network(d.data()['imageUrl'] as String, width: 56, height: 56, fit: BoxFit.cover)
                      : Container(width: 56, height: 56, color: Colors.grey[300])),
                  title: Text((d.data()['title'] as String?) ?? 'Scan'),
                  subtitle: Text('Clutter Score: ${(d.data()['clutterScore'] as num?)?.toStringAsFixed(1) ?? '-'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final data = d.data();
                    final url = (data['imageUrl'] as String?) ?? '';
                    final organized = data['organizedImageUrl'] as String?;
                    final labels = (data['labels'] as List?)?.cast<String>() ?? const <String>[];
                    final objectsRaw = (data['objects'] as List?) ?? const <dynamic>[];
                    final objects = objectsRaw.map((o) {
                      final box = o['box'] as Map<String, dynamic>? ?? const {};
                      return DetectedObject(
                        name: (o['name'] as String?) ?? 'object',
                        confidence: ((o['confidence'] as num?) ?? 0).toDouble(),
                        box: BoundingBoxNormalized(
                          left: ((box['left'] as num?) ?? 0).toDouble(),
                          top: ((box['top'] as num?) ?? 0).toDouble(),
                          width: ((box['width'] as num?) ?? 0).toDouble(),
                          height: ((box['height'] as num?) ?? 0).toDouble(),
                        ),
                      );
                    }).toList();
                    final analysis = VisionAnalysis(objects: objects, labels: labels);
                    if (url.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResultsScreen(image: NetworkImage(url), analysis: analysis, organizedUrl: organized),
                        ),
                      );
                    }
                  },
                ),
              ),
            const SizedBox(height: 8),
            _LoadMore(uid: uid, last: docs.isNotEmpty ? docs.last : null),
          ],
        );
      },
    );
  }
}

class _LoadMore extends StatefulWidget {
  const _LoadMore({required this.uid, required this.last});
  final String uid;
  final QueryDocumentSnapshot<Map<String, dynamic>>? last;
  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _extra = [];
  bool _loading = false;
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _loading ? null : _load,
        child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Load more'),
      ),
    );
  }

  Future<void> _load() async {
    if (widget.last == null) return;
    setState(() => _loading = true);
    final more = await FirebaseFirestore.instance
        .collection('analyses')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(widget.last!)
        .limit(5)
        .get();
    if (mounted) {
      setState(() {
        _extra.addAll(more.docs);
        _loading = false;
        _done = more.docs.isEmpty;
      });
    }
  }
}


