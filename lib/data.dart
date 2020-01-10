import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class Podcast with ChangeNotifier {
  RssFeed _feed;
  RssItem _selectedItem;

  RssFeed get feed => _feed;
  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;
  set selectedItem(RssItem value) {
    _selectedItem = value;
    notifyListeners();
  }
}

/// Info about whether a specific podcast episode has been downloaded.
class DownloadManager with ChangeNotifier {
  final pathSuffix = 'dashcast/downloads';
  Map<RssItem, DownloadData> _downloadData = {};

  DownloadManager();

  String downloadLocation(RssItem item) => _downloadData[item]?.location;

  double percentDownloaded(RssItem item) =>
      _downloadData[item]?.percentDownloaded;

  DownloadData downloadStatus(RssItem item) => _downloadData[item];

  void download(RssItem item) async {
    final req = http.Request('GET', Uri.parse(item.guid));
    final res = await req.send();
    if (res.statusCode != 200)
      throw Exception('Unexpected HTTP code: ${res.statusCode}');

    final contentLength = res.contentLength;
    var downloadedLength = 0;

    final file = File(await _getDownloadPath(path.split(item.guid).last));
    _downloadData[item] = DownloadData(item);
    res.stream
        .map((chunk) {
          downloadedLength += chunk.length;
          _downloadData[item].percentDownloaded =
              downloadedLength / contentLength;
          notifyListeners();
          return chunk;
        })
        .pipe(file.openWrite())
        .whenComplete(() {
          _downloadData[item].location = file.path;
          print('Downloading complete ${file.path}');
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

class DownloadData {
  RssItem episode;
  String location;
  double percentDownloaded = 0;
  DownloadData(this.episode);
}
