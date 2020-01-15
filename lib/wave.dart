import 'dart:math';

import 'package:flutter/material.dart';
//ignore: unused_import
import 'package:dashcast/notifiers.dart';
//ignore: unused_import
import 'package:provider/provider.dart';

final deg2rad = pi / 180.0;
final frequency = 4.0;
final amplitude = 10.0;
final maxDiff = 3.0;

class Wave extends StatefulWidget {
  final Size size;

  const Wave({Key key, @required this.size}) : super(key: key);

  @override
  _WaveState createState() => _WaveState();
}

class _WaveState extends State<Wave> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      height: widget.size.height,
      width: widget.size.width,
    );
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
