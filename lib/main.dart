// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dashcast/notifiers.dart';
import 'package:dashcast/player.dart';
import 'package:dashcast/alert_wiggle.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final url = 'https://itsallwidgets.com/podcast/feed';

void main() => runApp(MyApp());

class EpisodeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final episode = Provider.of<Episode>(context);
    final item = episode.item;

    return AlertWiggle(
      child: ListTile(
        leading: DownloadControl(),
        title: Text(item.title),
        subtitle: _subtitle(item.description),
        onTap: () => _onTap(context, episode),
      ),
    );
  }

  Text _subtitle(String description) {
    return Text(
      '\n' + description.trim(),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _onTap(BuildContext context, Episode episode) {
    Provider.of<Podcast>(context).selectedEpisode = episode;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerPage()),
    );
  }
}

class DownloadControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        LeadingImage(),
        DownloadButton(),
      ],
    );
  }
}

class LeadingImage extends StatelessWidget {
  final _defaultOpacity = 0.15;

  @override
  Widget build(BuildContext context) {
    final episode = Provider.of<Episode>(context);
    return Consumer<Episode>(
      builder: (BuildContext context, Episode value, Widget child) {
        return AnimatedOpacity(
          child: child,
          opacity: _getOpacity(value.percentDownloaded),
          duration: Duration(milliseconds: 100),
        );
      },
      child: Hero(
        child: ClipOval(
          child: PodcastImage(),
        ),
        tag: episode.item.title,
      ),
    );
  }

  double _getOpacity(double percentDownloaded) =>
      percentDownloaded * (1 - _defaultOpacity) + _defaultOpacity;
}

/*


App infra below this line.


*/

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
        return podcast.feed == null ? Loading() : EpisodeList();
      }),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}

class EpisodeList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);

    return ListView(
      children: podcast.feed.items
          .map(
            (i) => ChangeNotifierProvider(
              builder: (_) => Episode(i),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: EpisodeTile(),
              ),
            ),
          )
          .toList(),
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

/// This is part of the emergency offline-proofing for live-coding.
class PodcastImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    if (podcast.offline) return Image.asset('assets/podcast.jpg');
    return Image.network(podcast.feed.image.url);
  }
}
