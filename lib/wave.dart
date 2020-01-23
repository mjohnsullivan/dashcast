import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dashcast/notifiers.dart';
import 'package:provider/provider.dart';

class Wave extends StatefulWidget {
  final Size size;

  const Wave({Key key, @required this.size}) : super(key: key);

  @override
  _WaveState createState() => _WaveState();
}

class _WaveState extends State<Wave> with SingleTickerProviderStateMixin {
  List<Offset> _points;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
      upperBound: 2 * pi,
    );
    _initPoints();
    _controller.addListener(_newPoints);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayStatus>(
      builder: (context, player, child) {
        if (player.isPlaying) {
          _controller.repeat();
        } else {
          _controller.stop();
        }
        return child;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget child) {
          return ClipPath(
            clipper: WaveClipper(_controller.value, _points),
            child: BlueGradient(),
          );
        },
      ),
    );
  }

  /// Generates a random starting configuration for a 'sound wave' pattern.
  void _initPoints() {
    _points = [];
    Random r = Random();
    for (int i = 0; i < widget.size.width; i++) {
      double x = i.toDouble();

      // Set this point's y-coordinate to a random value
      // no greater than 80% of the container's height
      double y = r.nextDouble() * (widget.size.height * 0.8);

      _points.add(Offset(x, y));
    }
  }

  /// Modifies each point randomly by a maximum of +/- [maxDiff] pixels
  void _newPoints() {
    // The maximum number of pixels that points on a random wave can change by.
    final maxDiff = 3.0;
    Random r = Random();
    for (int i = 0; i < _points.length; i++) {
      var point = _points[i];

      // Generate a random number between  -maxDiff and +maxDiff
      double diff = maxDiff - r.nextDouble() * maxDiff * 2.0;

      // Ensure that point is constrained between 0 and the size of the container
      double newY = max(0.0, point.dy + diff);
      newY = min(widget.size.height, newY);

      Offset newPoint = Offset(point.dx, newY);
      _points[i] = newPoint;
    }
  }
}

class WaveClipper extends CustomClipper<Path> {
  double _value;
  List<Offset> _wavePoints;

  WaveClipper(this._value, this._wavePoints);

  @override
  Path getClip(Size size) {
    var path = Path();
    // _makeSineWave(size);
    path.addPolygon(_wavePoints, false);

    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
    path.close();
    return path;
  }

  //ignore: unused_element
  void _makeSineWave(Size size) {
    final amplitude = size.height / 3;
    final yOffset = amplitude;

    for (int x = 0; x < size.width; x++) {
      double y = amplitude * sin(x / 4) + yOffset;

      Offset newPoint = Offset(x.toDouble(), y);
      _wavePoints[x] = newPoint;
    }
  }

  //ignore: unused_element
  Path _bezierWave(Size size) {
    /*
    Adapted from 
    https://github.com/felixblaschke/simple_animations_example_app/blob/master/lib/examples/fancy_background.dart
    */

    final v = _value * pi * 2;
    final path = Path();

    final y1 = sin(v);
    final y2 = sin(v + pi / 2);
    final y3 = sin(v + pi);

    final startPointY = size.height * (0.5 + 0.4 * y1);
    final controlPointY = size.height * (0.5 + 0.4 * y2);
    final endPointY = size.height * (0.5 + 0.4 * y3);

    path.moveTo(size.width * 0, startPointY);
    path.quadraticBezierTo(
        size.width / 5, controlPointY, size.width, endPointY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class BlueGradient extends StatelessWidget {
  final overlayHeight = 50.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: overlayHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: FractionalOffset.topCenter,
          end: FractionalOffset.bottomCenter,
          colors: [
            Colors.blue,
            Colors.blue.withOpacity(0.25),
          ],
        ),
      ),
    );
  }
}
