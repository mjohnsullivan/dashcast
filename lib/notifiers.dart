import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show ByteData, rootBundle;

class PlayStatus with ChangeNotifier {
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  set isPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }
}

// Emergency offline manual: add variable to Podcast(offline: true) on main.dart line 101
// also Episode(i, offline: true) on line 143 in main.dart
class Podcast with ChangeNotifier {
  RssFeed _feed;
  Episode _selectedEpisode;
  // Hacked version for emergency offline capabilities.
  bool offline = false;

  Podcast({this.offline = false});

  RssFeed get feed => _feed;
  void parse(String url) async {
    if (offline) {
      final res = await rootBundle.loadString('assets/feed.xml');
      _feed = RssFeed.parse(res);
      notifyListeners();
      return;
    }

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
  Episode(this.item, {this.offline = false}) {
    if (offline) setUpFakeMp3();
  }

  bool _hasNotifiedDownloaded = false;
  RssItem item;
  String _location;
  double _percentDownloaded = 0;
  bool offline;

  double get percentDownloaded => _percentDownloaded;

  bool get hasNotifiedDownloaded => _hasNotifiedDownloaded;

  void downloadNotified() => _hasNotifiedDownloaded = true;

  String get downloadLocation => _location;

  Future setUpFakeMp3() async {
    // Dumb copy of code from assets to a local file.
    // Workaround for: https://github.com/flutter/flutter/issues/28162
    String path = await _getDownloadPath('offline.mp3');
    var data = await rootBundle.load('assets/surf_shimmy.mp3');
    var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    var file = File(path);
    await file.writeAsBytes(bytes);
    _location = file.path;
  }

  Future offlineDownload() async {
    await setUpFakeMp3();
    notifyListeners();
    // Simulate a Download that takes 1.2 seconds.
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      _percentDownloaded += .1;
      notifyListeners();
      if (_percentDownloaded >= 1) {
        // To guard against weird floating point errors.
        _percentDownloaded = 1;
        timer.cancel();
      }
    });
  }

  Future download() async {
    if (offline) {
      return offlineDownload();
    }
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

class OfflinePodcast extends Podcast {
  RssFeed _feed;
  Episode _selectedEpisode;

  RssFeed get feed => _feed;
  void parse(String url) async {
    final res = await rootBundle.loadString('assets/feed.rss');
    _feed = RssFeed.parse(res);
    notifyListeners();
  }

  Episode get selectedEpisode => _selectedEpisode;
  set selectedEpisode(Episode value) {
    _selectedEpisode = value;
    notifyListeners();
  }
}
