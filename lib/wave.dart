import 'dart:math';

import 'package:dashcast/notifiers.dart';
import 'package:flutter/material.dart';
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
  AnimationController _controller;
  List<Offset> _points = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    Random r = Random();
    for (int i = 0; i < widget.size.width; i++) {
      double x = i.toDouble();
      double y = r.nextDouble() * (widget.size.height * 0.8);

      _points.add(Offset(x, y));
    }

    _controller.addListener(() {
      Random r = Random();
      for (int i = 0; i < _points.length; i++) {
        var point = _points[i];

        double diff = maxDiff - r.nextDouble() * maxDiff * 2.0;
        double newY = max(0.0, point.dy + diff);
        newY = min(widget.size.height, newY);

        Offset newPoint = Offset(point.dx, newY);
        _points[i] = newPoint;
      }
    });
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
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.transparent,
              height: widget.size.height,
              width: widget.size.width,
            ),
            OpacityOverlay(height: widget.size.height),
          ],
        ),
        builder: (BuildContext context, Widget child) {
          return ClipPath(
            clipper: WaveClipper(_controller.value, _points),
            child: child,
          );
        },
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  double value;
  List<Offset> wavePoints;

  WaveClipper(this.value, this.wavePoints);

  @override
  Path getClip(Size size) {
    var path = Path();
    path.addPolygon(wavePoints, false);

    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
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
            Colors.blue.withOpacity(0.0),
          ],
          stops: [0.0, 1.0],
        ),
      ),
    );
  }
}
