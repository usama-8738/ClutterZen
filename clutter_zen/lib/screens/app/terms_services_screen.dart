import 'package:flutter/material.dart';

class TermsServicesScreen extends StatelessWidget {
  const TermsServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Terms & Services')),
        body: Column(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _TabsHeader(),
            ),
            Expanded(child: _TabsBody()),
          ],
        ),
      ),
    );
  }
}

class _TabsHeader extends StatelessWidget {
  const _TabsHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: const TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        indicator: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(12))),
        tabs: [Tab(text: 'Overview'), Tab(text: 'Privacy'), Tab(text: 'Usage')],
      ),
    );
  }
}

class _TabsBody extends StatelessWidget {
  const _TabsBody();
  @override
  Widget build(BuildContext context) {
    return const TabBarView(children: [
      _TermsBody(title: 'Overview'),
      _TermsBody(title: 'Privacy'),
      _TermsBody(title: 'Usage'),
    ]);
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum vitae tortor vitae dolor consequat gravida. Integer vehicula, dui in dignissim venenatis, velit nisl molestie leo, non sodales arcu libero non felis.'),
      ],
    );
  }
}


