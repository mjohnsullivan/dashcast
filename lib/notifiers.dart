import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:webfeed/domain/rss_item.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:webfeed/webfeed.dart';

class Podcast with ChangeNotifier {
  EpisodeFeed _feed;
  Episode _selectedItem;

  EpisodeFeed get feed => _feed;
  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = EpisodeFeed.parse(xmlStr);
    notifyListeners();
  }

  Episode get selectedItem => _selectedItem;
  set selectedItem(Episode value) {
    _selectedItem = value;
    notifyListeners();
  }
}

class EpisodeFeed extends RssFeed {
  final RssFeed _feed;
  List<Episode> items;

  EpisodeFeed(this._feed) {
    items = _feed.items.map((i) => Episode(i)).toList();
  }

  RssImage get image => _feed.image;

  static EpisodeFeed parse(xmlStr) {
    return EpisodeFeed(RssFeed.parse(xmlStr));
  }
}

class Episode extends RssItem with ChangeNotifier {
  String downloadLocation;
  RssItem _item;

  Episode(this._item);

  String get title => _item.title;
  String get description => _item.description;
  String get guid => _item.guid;

  void download([Function(double) updates]) async {
    final req = http.Request('GET', Uri.parse(_item.guid));
    final res = await req.send();
    if (res.statusCode != 200)
      throw Exception('Unexpected HTTP code: ${res.statusCode}');

    final contentLength = res.contentLength;
    var downloadedLength = 0;

    String filePath = await _getDownloadPath(path.split(_item.guid).last);
    final file = File(filePath);
    res.stream
        .map((chunk) {
          downloadedLength += chunk.length;
          if (updates != null) updates(downloadedLength / contentLength);
          return chunk;
        })
        .pipe(file.openWrite())
        .whenComplete(() {
          // TODO save this to sharedprefs or similar.
          downloadLocation = filePath;
          notifyListeners();
        })
        .catchError((e) => print('An Error has occurred!!!: $e'));
  }

  Future<String> _getDownloadPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final prefix = dir.path;
    final absolutePath = path.join(prefix, filename);
    print(absolutePath);
    return absolutePath;
  }
}
