// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:dashcast/notifiers.dart';
import 'package:dashcast/player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart';

final url = 'https://itsallwidgets.com/podcast/feed';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (_) => Podcast()..parse(url),
      child: MaterialApp(
        title: 'Dashcast',
        home: EpisodesPage(),
      ),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<Podcast>(builder: (context, podcast, _) {
        return podcast.feed != null
            ? ListView(
                children: podcast.feed.items
                    .map(
                      (i) => ChangeNotifierProvider(
                        builder: (_) => Episode(i),
                        child: PodcastTile(),
                      ),
                    )
                    .toList(),
              )
            : Center(
                child: CircularProgressIndicator(),
              );
      }),
    );
  }
}

class PodcastTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final episode = Provider.of<Episode>(context);
    final item = episode.item;
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: AlertWiggle(
        child: ListTile(
          leading: DownloadControl(),
          title: Text(item.title),
          subtitle: Text(
            '\n' + item.description.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Provider.of<Podcast>(context).selectedEpisode = episode;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlayerPage()),
            );
          },
        ),
      ),
    );
  }
}

class DownloadControl extends StatelessWidget {
  final _defaultOpacity = .15;

  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        Consumer<Episode>(
          builder: (BuildContext context, Episode episode, Widget child) {
            var percentDownloaded = episode.percentDownloaded;
            return AnimatedOpacity(
              duration: Duration(milliseconds: 100),
              opacity:
                  percentDownloaded * (1 - _defaultOpacity) + _defaultOpacity,
              child: child,
            );
          },
          child: Hero(
              child: ClipOval(
                child: Image.network(podcast.feed.image.url),
              ),
              tag: Provider.of<Episode>(context).item.title),
        ),
        DownloadButton(),
      ],
    );
  }
}

class DownloadButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final episode = Provider.of<Episode>(context);
    return Consumer<Episode>(
      builder: (BuildContext context, Episode episode, Widget child) {
        return Visibility(
          visible: episode.percentDownloaded == 0,
          child: child,
        );
      },
      child: IconButton(
          icon: Icon(Icons.file_download),
          onPressed: () {
            episode.download();
            Scaffold.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloading ${episode.item.title}'),
              ),
            );
          }),
    );
  }
}

// TODO(fitza): make stateless?
class AlertWiggle extends StatefulWidget {
  AlertWiggle({this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() => _AlertWiggleState();
}

class _AlertWiggleState extends State<AlertWiggle> {
  static final sinePeriod = 2 * pi;
  double _endValue = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<Episode>(builder: (_, episode, __) {
      if (episode.percentDownloaded == 1 && !episode.hasNotifiedDownloaded) {
        _endValue += sinePeriod;
        episode.downloadNotified();
      }
      return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: _endValue),
          duration: Duration(milliseconds: 200),
          child: widget.child,
          builder: (_, double value, Widget child) {
            var offset = sin(value * 2);
            return Transform(
                transform: Matrix4.translation(Vector3(offset, offset * 2, 0)),
                child: Material(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: value == 0 || value == _endValue ? 0 : 3,
                  child: child,
                ));
          });
    });
  }
}
