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
            ? ListView(
                children:
                    podcast.feed.items.map((i) => PodcastTile(i)).toList(),
              )
            : Center(
                child: CircularProgressIndicator(),
              );
      }),
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
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Wiggle(
        animation: _animationController,
        child: ElevationOnAnimate(
          animation: _animationController,
          child: ListTile(
            leading: DownloadControl(widget._item, _animationController),
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
      ),
    );
  }
}

class DownloadControl extends StatelessWidget {
  const DownloadControl(this._item, this._animationController);

  final _defaultOpacity = .15;
  final RssItem _item;
  final AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        Hero(
            child: ClipOval(
              child: Consumer<DownloadManager>(
                  child: Image.network(podcast.feed.image.url),
                  builder: (BuildContext context, DownloadManager manager,
                      Widget child) {
                    var percentDownloaded =
                        manager.downloadStatus(_item).percentDownloaded;
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 100),
                      opacity: percentDownloaded * (1 - _defaultOpacity) +
                          _defaultOpacity,
                      child: child,
                    );
                  }),
            ),
            tag: _item.title),
        DownloadButton(_item, _animationController),
      ],
    );
  }
}

class DownloadButton extends StatelessWidget {
  const DownloadButton(this._item, this._animationController);

  final RssItem _item;
  final AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (BuildContext context, DownloadManager manager, Widget child) {
        var status = manager.downloadStatus(_item);
        return Visibility(
          visible: status.percentDownloaded == 0,
          child: child,
        );
      },
      child: IconButton(
          icon: Icon(Icons.file_download),
          onPressed: () {
            Provider.of<DownloadManager>(context).download(_item).then((_) =>
                _animationController
                    .forward()
                    .then((_) => _animationController.reverse()));
            Scaffold.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloading ${_item.title}'),
              ),
            );
          }),
    );
  }
}

class Wiggle extends AnimatedWidget {
  Wiggle({@required Animation<double> animation, this.child})
      : super(listenable: sinePeriod.animate(animation));

  final Widget child;
  static final sinePeriod = Tween<double>(begin: 0, end: 2 * pi);

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

class ElevationOnAnimate extends AnimatedWidget {
  ElevationOnAnimate({@required Animation<double> animation, this.child})
      : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    return Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        elevation: animation.value > 0 ? 3 : 0,
        child: child);
  }
}
