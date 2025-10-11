import 'package:flutter/material.dart';

class TermsServicesScreen extends StatelessWidget {
  const TermsServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Terms & Services'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Privacy'),
            Tab(text: 'Usage'),
          ]),
        ),
        body: const TabBarView(children: [
          _TermsBody(title: 'Overview'),
          _TermsBody(title: 'Privacy'),
          _TermsBody(title: 'Usage'),
        ]),
      ),
    );
  }
}

class TermsServicesAlt2Screen extends StatelessWidget {
  const TermsServicesAlt2Screen({super.key});
  @override
  Widget build(BuildContext context) => const _TermsBody(title: 'Terms (Alt 2)');
}

class TermsServicesAlt3Screen extends StatelessWidget {
  const TermsServicesAlt3Screen({super.key});
  @override
  Widget build(BuildContext context) => const _TermsBody(title: 'Terms (Alt 3)');
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


