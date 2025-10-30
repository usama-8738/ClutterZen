import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, this.background, this.onReady});

  final ImageProvider? background; // optional blurred backdrop
  final Future<void> Function(BuildContext context)?
      onReady; // optional task to run then navigate

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  static const _lottieUrl =
      'https://lottie.host/0bd5139f-6801-4bfe-abdf-e4e03d90ab03/2DCtc5jJKu.json';
  final List<String> _steps = const [
    'Detecting objects...',
    'Analyzing clutter level...',
    'Generating solutions...'
  ];
  final List<String> _tips = const [
    'Tip: Group similar items to reduce visual noise.',
    'Tip: Clear flat surfaces first for fast wins.',
    'Tip: Label bins to keep organization sustainable.',
  ];

  int _currentStep = 0;
  int _tipIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Kick off async task if provided, after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cb = widget.onReady;
      if (cb != null) {
        await cb(context);
      }
    });
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (!mounted) return;
      setState(() {
        _currentStep = (_currentStep + 1) % (_steps.length + 1); // loops
        _tipIndex = (_tipIndex + 1) % _tips.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        actions: [
          Row(children: const [
            Icon(Icons.camera_alt_outlined),
            SizedBox(width: 4),
            Text('3'),
            SizedBox(width: 12)
          ])
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.background != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                        Colors.black.withAlpha(128), BlendMode.srcATop),
                    child: Image(image: widget.background!, fit: BoxFit.cover),
                  )
                : Container(color: Colors.grey[800]),
          ),
          Center(
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.network(_lottieUrl, repeat: true)),
                  const SizedBox(height: 16),
                  Text('Analyzing Your Image',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  // Steps
                  for (int i = 0; i < _steps.length; i++)
                    _ProcessingStep(
                        text: _steps[i],
                        isActive: _currentStep == i,
                        isComplete: _currentStep > i),
                  const SizedBox(height: 16),
                  Text(_tips[_tipIndex],
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep(
      {required this.text, required this.isActive, required this.isComplete});
  final String text;
  final bool isActive;
  final bool isComplete;
  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (isComplete) {
      icon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (isActive) {
      icon = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2));
    } else {
      icon = Icon(Icons.circle_outlined, color: Colors.grey[400], size: 20);
    }
    final style = isActive
        ? Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: style))
        ],
      ),
    );
  }
}
