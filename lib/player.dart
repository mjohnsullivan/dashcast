import 'dart:async';

import 'package:dashcast/main.dart';
import 'package:dashcast/notifiers.dart';
import 'package:dashcast/wave.dart';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:provider/provider.dart';

class EpisodeImage extends StatelessWidget {
  final title;

  const EpisodeImage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Hero(child: PodcastImage(), tag: title),
        AnimatedOpacity(
            opacity: Provider.of<PlayStatus>(context).isPlaying ? 1.0 : 0.0,
            duration: Duration(seconds: 1),
            child: Wave(size: Size(MediaQuery.of(context).size.width, 50))),
      ],
    );
  }
}

class _PlaybackButtonState extends State<PlaybackButtons>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final episode = Provider.of<Podcast>(context).selectedEpisode;
    final item = episode.item;
    final downloadLocation = episode.downloadLocation;
    final playStatus = Provider.of<PlayStatus>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ProgressSlider(position: _playPosition),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RewindButton(),
            IconButton(
              icon: AnimatedIcon(
                progress: _animationController,
                icon: AnimatedIcons.play_pause,
              ),
              onPressed: () {
                if (playStatus.isPlaying) {
                  _animationController.reverse();
                  _stop();
                } else {
                  _animationController.forward();
                  _play(downloadLocation ?? item.guid);
                }
              },
            ),
            FastForward(),
          ],
        ),
      ],
    );
  }

  sound.FlutterSound _sound;
  double _playPosition;
  StreamSubscription<sound.PlayStatus> _playerSubscription;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _sound = sound.FlutterSound();
    _playPosition = 0;
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
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
    final playStatus = Provider.of<PlayStatus>(context);
    playStatus.isPlaying = false;
  }

  void _play(String url) async {
    final playStatus = Provider.of<PlayStatus>(context);
    playStatus.isPlaying = true;
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged.listen((e) {
      if (e != null) {
        setState(() => _playPosition = (e.currentPosition / e.duration));
      }
    });
  }
}

class PlayPauseIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playStatus = Provider.of<PlayStatus>(context);

    return Icon(playStatus.isPlaying ? Icons.pause : Icons.play_arrow);
  }
}

class PlaybackButtons extends StatefulWidget {
  @override
  _PlaybackButtonState createState() => _PlaybackButtonState();
}

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
              EpisodeImage(
                title: podcast.selectedEpisode.item.title,
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

class ProgressSlider extends StatelessWidget {
  const ProgressSlider({
    Key key,
    @required double position,
  })  : _playPosition = position,
        super(key: key);

  final double _playPosition;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _playPosition,
      onChanged: null,
    );
  }
}

class FastForward extends StatelessWidget {
  const FastForward({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.fast_forward),
      onPressed: null,
    );
  }
}

class RewindButton extends StatelessWidget {
  const RewindButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(Icons.fast_rewind), onPressed: null);
  }
}
