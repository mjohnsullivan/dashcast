// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dashcast/notifiers.dart';
import 'package:dashcast/player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'alert_wiggle.dart';
import 'package:webfeed/domain/rss_item.dart';

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

class EpisodeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final episode = Provider.of<Episode>(context);
    final item = episode.item;

    return Padding(
      padding: const EdgeInsets.all(3.0),
      // TODO(live): Wrap with AlertWiggle
      child: ListTile(
        leading: DownloadControl(),
        title: Text(item.title),
        subtitle: _subtitle(item),
        onTap: () => _onTap(context, episode),
      ),
    );
  }

  Text _subtitle(RssItem item) {
    return Text(
      '\n' + item.description.trim(),
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

class EpisodeImage extends StatelessWidget {
  final _defaultOpacity = .15;

  const EpisodeImage({
    Key key,
    @required this.podcast,
  }) : super(key: key);

  final Podcast podcast;

  @override
  Widget build(BuildContext context) {
    return Consumer<Episode>(
      builder: (BuildContext context, Episode episode, Widget child) {
        var percentDownloaded = episode.percentDownloaded;
        return AnimatedOpacity(
          duration: Duration(milliseconds: 100),
          opacity: _getOpacity(percentDownloaded),
          child: child,
        );
      },
      child: Hero(
        child: ClipOval(
          child: Image.network(podcast.feed.image.url),
        ),
        tag: Provider.of<Episode>(context).item.title,
      ),
    );
  }

  double _getOpacity(double percentDownloaded) =>
      percentDownloaded * (1 - _defaultOpacity) + _defaultOpacity;
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
              child: EpisodeTile(),
            ),
          )
          .toList(),
    );
  }
}

class DownloadControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        EpisodeImage(podcast: podcast),
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
