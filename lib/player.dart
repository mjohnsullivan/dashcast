import 'dart:async';

import 'package:dashcast/notifiers.dart';
import 'package:dashcast/wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:provider/provider.dart';

class PlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (_) => PlayStatus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            Provider.of<Podcast>(context).selectedEpisode.item.title,
          ),
        ),
        body: SafeArea(child: Player()),
      ),
    );
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Column(
      children: [
        Flexible(
          flex: 8,
          child: SingleChildScrollView(
            child: Column(children: [
              Stack(
                overflow: Overflow.visible,
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  Hero(
                      child: Image.network(podcast.feed.image.url),
                      tag: podcast.selectedEpisode.item.title),
                  AnimatedOpacity(
                      opacity: Provider.of<PlayStatus>(context).isPlaying
                          ? 1.0
                          : 0.0,
                      duration: Duration(seconds: 1),
                      child: Wave(
                          size: Size(MediaQuery.of(context).size.width, 50))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  podcast.selectedEpisode.item.description.trim(),
                ),
              ),
            ]),
          ),
        ),
        Flexible(
          flex: 2,
          child: Material(
            elevation: 12,
            child: AudioControls(),
          ),
        ),
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlaybackButtons(),
      ],
    );
  }
}

class PlaybackButtons extends StatefulWidget {
  @override
  _PlaybackButtonState createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButtons>
    with SingleTickerProviderStateMixin {
  sound.FlutterSound _sound;
  double _playPosition;
  StreamSubscription<sound.PlayStatus> _playerSubscription;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _sound = sound.FlutterSound();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _playPosition = 0;
  }

  @override
  void dispose() {
    // TODO cleanly clean things up. Since _cleanup is async, sometimes the
    // _playerSubscription listener calls setState after dispose but before it's canceled.
    _cleanup();
    _animationController.dispose();
    super.dispose();
  }

  void _cleanup() async {
    if (_sound.isPlaying) await _sound.stopPlayer();
    _playerSubscription?.cancel();
  }

  void _stop() async {
    await _sound.stopPlayer();
    _animationController.reverse();
    final animation = Provider.of<PlayStatus>(context);
    animation.isPlaying = false;
  }

  void _play(String url) async {
    _animationController.forward();
    final animation = Provider.of<PlayStatus>(context);
    animation.isPlaying = true;
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged.listen((e) {
      if (e != null) {
        setState(() => _playPosition = (e.currentPosition / e.duration));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final episode = Provider.of<Podcast>(context).selectedEpisode;
    final item = episode.item;
    final downloadLocation = episode.downloadLocation;

    final animation = Provider.of<PlayStatus>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Slider(
          value: _playPosition,
          onChanged: null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(icon: Icon(Icons.fast_rewind), onPressed: null),
            IconButton(
              icon: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: _animationController),
              onPressed: () {
                if (animation.isPlaying) {
                  _stop();
                } else {
                  _play(downloadLocation ?? item.guid);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: null,
            ),
          ],
        ),
      ],
    );
  }
}
