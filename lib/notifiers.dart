import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PlayStatus with ChangeNotifier {
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  set isPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }
}

class Podcast with ChangeNotifier {
  RssFeed _feed;
  Episode _selectedEpisode;

  RssFeed get feed => _feed;
  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  Episode get selectedEpisode => _selectedEpisode;
  set selectedEpisode(Episode value) {
    _selectedEpisode = value;
    notifyListeners();
  }
}

class Episode with ChangeNotifier {
  Episode(this.item);

  bool _hasNotifiedDownloaded = false;
  RssItem item;
  String _location;
  double _percentDownloaded = 0;

  double get percentDownloaded => _percentDownloaded;

  bool get hasNotifiedDownloaded => _hasNotifiedDownloaded;

  void downloadNotified() => _hasNotifiedDownloaded = true;

  String get downloadLocation => _location;

  Future download() async {
    final req = http.Request('GET', Uri.parse(item.guid));
    final res = await req.send();
    if (res.statusCode != 200)
      throw Exception('Unexpected HTTP code: ${res.statusCode}');

    final contentLength = res.contentLength;
    var downloadedLength = 0;

    final file = File(await _getDownloadPath(path.split(item.guid).last));
    return res.stream
        .map((chunk) {
          downloadedLength += chunk.length;
          _percentDownloaded = downloadedLength / contentLength;
          notifyListeners();
          return chunk;
        })
        .pipe(file.openWrite())
        .whenComplete(() {
          _location = file.path;
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
