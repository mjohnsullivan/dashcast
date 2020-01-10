// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:dashcast/data.dart';
import 'package:dashcast/player.dart';
import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart';

final url = 'https://itsallwidgets.com/podcast/feed';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (_) => Podcast()..parse(url)),
        ChangeNotifierProvider(builder: (_) => DownloadManager()),
      ],
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
            ? EpisodeListView(rssFeed: podcast.feed)
            : Center(
                child: CircularProgressIndicator(),
              );
      }),
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items.map((i) => PodcastTile(i)).toList(),
    );
  }
}

class PodcastTile extends StatefulWidget {
  final RssItem _item;
  PodcastTile(this._item);
  @override
  _PodcastTileState createState() => _PodcastTileState();
}

class _PodcastTileState extends State<PodcastTile>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  final _defaultOpacity = .15;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: AnimatedBuilder(
          animation: _animationController,
          builder: (BuildContext context, _) {
            // TODO child^.
            return Wiggle(
              animation: _animationController,
              child: Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: _animationController.value > 0
                    ? 3
                    : 0, // TODO(efortuna) ???
                child: ListTile(
                  leading: Stack(
                    alignment: AlignmentDirectional.center,
                    children: <Widget>[
                      Hero(
                          child: ClipOval(
                            child: Consumer<DownloadManager>(
                                child: Image.network(podcast.feed.image.url),
                                builder: (_, downloadInfo, child) {
                                  if (downloadInfo.percentDownloaded == 1) {
                                    _animationController.forward().then(
                                        (_) => _animationController.reverse());
                                  }
                                  return AnimatedOpacity(
                                    duration: Duration(milliseconds: 100),
                                    opacity: downloadInfo.percentDownloaded *
                                            (1 - _defaultOpacity) +
                                        _defaultOpacity,
                                    child: child,
                                  );
                                }),
                          ),
                          tag: widget._item.title),
                      Selector<DownloadManager, bool>(
                        selector: (_, downloadInfo) =>
                            downloadInfo.percentDownloaded == 0,
                        builder: (BuildContext context, bool isVisible,
                            Widget child) {
                          return IconButton(
                              icon: Icon(Icons.file_download),
                              onPressed: () {
                                Provider.of<DownloadManager>(context)
                                    .download();
                                Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Downloading ${widget._item.title}'),
                                  ),
                                );
                              }); //TODO
                          return Visibility(
                            visible: isVisible,
                            child: child,
                          );
                        },
                      ),
                    ],
                  ),
                  title: Text(widget._item.title),
                  subtitle: Text(
                    '\n' + widget._item.description.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Provider.of<Podcast>(context).selectedItem = widget._item;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlayerPage()),
                    );
                  },
                ),
              ),
            );
          }),
    );
  }
}

class Wiggle extends AnimatedWidget {
  final Widget child;
  static final sinePeriod = Tween<double>(begin: 0, end: 2 * pi);
  Wiggle({@required Animation<double> animation, this.child})
      : super(listenable: sinePeriod.animate(animation));

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    var offset = sin(animation.value);
    return Transform(
      child: child,
      transform: Matrix4.translation(Vector3(offset, offset * 2, 0)),
    );
  }
}
