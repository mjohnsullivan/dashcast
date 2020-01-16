import 'dart:math';

import 'package:flutter/material.dart';
//ignore: unused_import
import 'package:dashcast/notifiers.dart';
//ignore: unused_import
import 'package:provider/provider.dart';

final maxDiff = 3.0;

class Wave extends StatefulWidget {
  final Size size;

  const Wave({Key key, @required this.size}) : super(key: key);

  @override
  _WaveState createState() => _WaveState();
}

class _WaveState extends State<Wave> with SingleTickerProviderStateMixin {
  List<Offset> _points = [];
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _controller.addListener(_newPoints);
    _initPoints();
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
        child: Container(
          color: Colors.transparent,
          height: widget.size.height,
          width: widget.size.width,
        ));
  }

  void _initPoints() {
    Random r = Random();
    for (int i = 0; i < widget.size.width; i++) {
      double x = i.toDouble();
      double y = r.nextDouble() * (widget.size.height * 0.8);

      _points.add(Offset(x, y));
    }
  }

  void _newPoints() {
    Random r = Random();
    for (int i = 0; i < _points.length; i++) {
      var point = _points[i];

      double diff = maxDiff - r.nextDouble() * maxDiff * 2.0;
      double newY = max(0.0, point.dy + diff);
      newY = min(widget.size.height, newY);

      Offset newPoint = Offset(point.dx, newY);
      _points[i] = newPoint;
    }
  }
}

class WaveClipper extends CustomClipper<Path> {
  double value;
  List<Offset> wavePoints;

  WaveClipper(this.value, this.wavePoints);

  @override
  Path getClip(Size size) {
    var path = _soundWave(size);
    // var path = _sineWave(size);
    // var path = _bezierWave(size);
    return path;
  }

  //ignore: unused_element
  Path _soundWave(Size size) {
    var path = Path();
    path.addPolygon(wavePoints, false);

    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
    path.close();
    return path;
  }

  //ignore: unused_element
  Path _sineWave(Size size) {
    List<Offset> sinePoints = [];
    final speed = 2;
    final amplitude = size.height / 3;
    final yOffset = size.height / 2;

    final period = speed * value * 2 * pi;

    for (int i = 0; i < size.width; i++) {
      double y = amplitude * sin(0.075 * i - period) + yOffset;

      Offset newPoint = Offset(i.toDouble(), y);
      sinePoints.add(newPoint);
    }

    var path = Path();
    path.addPolygon(sinePoints, false);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  //ignore: unused_element
  Path _bezierWave(Size size) {
    /*
    Adapted from 
    https://github.com/felixblaschke/simple_animations_example_app/blob/master/lib/examples/fancy_background.dart
    */

    final v = value * pi * 2;
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

class OpacityOverlay extends StatelessWidget {
  final double height;

  const OpacityOverlay({Key key, @required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: FractionalOffset.topCenter,
          end: FractionalOffset.bottomCenter,
          colors: [
            Colors.blue,
            Colors.blue.withOpacity(0.25),
          ],
          stops: [0.0, 1.0],
        ),
      ),
    );
  }
}
