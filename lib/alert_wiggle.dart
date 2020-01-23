import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcast/notifiers.dart';

class AlertWiggle extends StatelessWidget {
  AlertWiggle({this.child});

  final Widget child;
  static final sinePeriod = 2 * pi;
  double _endValue = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<Episode>(builder: (_, episode, __) {
      // TODO(live): wrap child in TweenAnimationBuilder
      return child;
    });
  }
}
