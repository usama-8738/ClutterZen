import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider(
      {super.key,
      required this.before,
      required this.after,
      this.height = 260});

  final ImageProvider before;
  final ImageProvider after;
  final double height;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = 0.5; // 0 -> before only, 1 -> after only

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32; // account for padding
    return Container(
      height: widget.height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // After image (bottom full)
            Positioned.fill(
                child: Image(image: widget.after, fit: BoxFit.cover)),
            // Before image (clipped by position)
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: _position,
                child: Image(
                    image: widget.before, fit: BoxFit.cover, width: width),
              ),
            ),
            // Divider line
            Positioned(
              left: width * _position - 1.5,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: Colors.white),
            ),
            // Handle
            Positioned(
              left: width * _position - 20,
              top: widget.height / 2 - 20,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _position += details.delta.dx / width;
                    if (_position < 0) _position = 0;
                    if (_position > 1) _position = 1;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withAlpha(64), blurRadius: 6)
                      ]),
                  child:
                      const Icon(Icons.compare_arrows, color: Colors.black87),
                ),
              ),
            ),
            // Labels
            Positioned(
              left: 10,
              top: 10,
              child: _chip('BEFORE', Colors.red),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _chip('AFTER', Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
