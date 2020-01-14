import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:dashcast/notifiers.dart';

class AlertWiggle extends StatelessWidget {
  AlertWiggle({this.child});

  final Widget child;
  static final sinePeriod = 2 * pi;
  double _endValue = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<Episode>(builder: (_, episode, __) {
      if (episode.percentDownloaded == 1 && !episode.hasNotifiedDownloaded) {
        _endValue += sinePeriod;
        episode.downloadNotified();
      }

      return null;
      // TODO(live): replace null with:
      /*
      TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: _endValue),
          duration: Duration(milliseconds: 200),
          child: child,
          builder: (_, double value, Widget child) {
            return _transform(child: child, value: value);
          });
      */
    });
  }

  Widget _transform({@required Widget child, @required double value}) {
    double offset = sin(value * 2);
    return Transform(
        transform: Matrix4.translation(Vector3(offset, offset * 2, 0)),
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          elevation: value == 0 || value == _endValue ? 0 : 3,
          child: child,
        ));
  }
}
