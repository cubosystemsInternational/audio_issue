import 'dart:async';
import 'package:seekbar/seekbar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

class PlayAudio extends StatefulWidget {
  State<StatefulWidget> createState() => _PlayAudioState();
}

class _PlayAudioState extends State<PlayAudio> {
  AudioPlayer audioPlayer = AudioPlayer();

  bool _isLoading = true;
  double _audioProgress = 0; //milliseconds
  int _totalDuration = 0; //milliseconds
  List<String> _playlistAudioURLs = [];
  int _currentAudioIndex = 0;
  String _currentPlay;

  AudioPlayerState _playerState = AudioPlayerState.STOPPED;

  StreamSubscription<AudioPlayerState> _onPlayerStateChanged;
  StreamSubscription<void> _onPlayerCompleted;
  StreamSubscription<Duration> _onDurationChanged;
  StreamSubscription<Duration> _onAudioPositionChanged;
  final _scrollController = ScrollController();

  void togglePlay() {
    if (_playerState == AudioPlayerState.PLAYING) {
      audioPlayer.pause();
    } else if (_playerState == AudioPlayerState.PAUSED) {
      audioPlayer.resume();
    } else {
      audioPlayer.play(_playlistAudioURLs[_currentAudioIndex]);
    }
  }

  @override
  void initState() {
    super.initState();
    AudioPlayer.logEnabled = true;
    _getBooksInPlaylist();

    _onPlayerStateChanged = audioPlayer.onPlayerStateChanged.listen((event) {
      setState(() {
        _playerState = event;
      });
    });

    _onDurationChanged = audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration.inMilliseconds;
      });
    });

    _onAudioPositionChanged =
        audioPlayer.onAudioPositionChanged.listen((event) {
      setState(() {
        _audioProgress = event.inMilliseconds / _totalDuration;
      });
    });

    _onPlayerCompleted = audioPlayer.onPlayerCompletion.listen((event) {
      try {
        final audio = _playlistAudioURLs.elementAt(++_currentAudioIndex);
        setState(() {
          _currentPlay = audio;
        });
        audioPlayer.play(audio);
      } catch (err) {
        Navigator.of(context).pop();
      }
    });
  }

  void _getBooksInPlaylist() async {
    setState(() {
      _isLoading = false;
    });

    await audioPlayer.setReleaseMode(ReleaseMode.STOP);

    _doPlay();
  }

  void _doPlay() async {
    await audioPlayer.stop();
    _playerState = AudioPlayerState.STOPPED;

    _setBookAudioToPlaylist();

    togglePlay();
  }

  void _setBookAudioToPlaylist() {
    _playlistAudioURLs.clear();
    _playlistAudioURLs.addAll([
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3'
    ]);

    _currentPlay = _playlistAudioURLs.first;
  }

  @override
  void dispose() {
    audioPlayer.release();
    _onPlayerStateChanged.cancel();
    _onPlayerCompleted.cancel();
    _onDurationChanged.cancel();
    _onAudioPositionChanged.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  String localFilePath;

  IconData _renderPlayPauseIcon(AudioPlayerState state) {
    IconData _iconData;
    switch (state) {
      case AudioPlayerState.STOPPED:
        _iconData = Icons.play_arrow;
        break;
      case AudioPlayerState.PLAYING:
        _iconData = Icons.pause;
        break;
      case AudioPlayerState.PAUSED:
        _iconData = Icons.play_arrow;
        break;
      case AudioPlayerState.COMPLETED:
        _iconData = Icons.pause;
        break;
    }

    return _iconData;
  }

  void _next() {
    setState(() {
      ++_currentAudioIndex;
      _currentPlay = _playlistAudioURLs[_currentAudioIndex];
    });

    audioPlayer.play(_playlistAudioURLs[_currentAudioIndex]);
    _scrollController.animateTo((250 * _currentAudioIndex).toDouble(),
        duration: Duration(milliseconds: 100), curve: Curves.easeIn);
  }

  void _prev() {
    setState(() {
      --_currentAudioIndex;
      _currentPlay = _playlistAudioURLs[_currentAudioIndex];
    });
    audioPlayer.play(_playlistAudioURLs[_currentAudioIndex]);
    _scrollController.animateTo((250 * _currentAudioIndex).toDouble(),
        duration: Duration(milliseconds: 100), curve: Curves.easeIn);
  }

  void _onSeekbarChanged(double val) {
    //convert seek bar value to milliseconds
    final seekTo = (val * _totalDuration).toInt();
    audioPlayer.seek(Duration(milliseconds: seekTo));
  }

  Widget renderSavedPlayListAudioItem(String url, BuildContext context,
          bool isPlaying, ScrollController controller) =>
      GestureDetector(
        onTap: () {
          audioPlayer.play(url);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                color: Colors.blue[100],
                border: Border.fromBorderSide(isPlaying
                    ? BorderSide(color: Colors.red, width: 3)
                    : BorderSide(color: Colors.grey.shade600, width: 1))),
            height: 150,
            width: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              child: Container(
                child: Text(url),
              ),
            ),
          ),
        ),
      );

  double height(BuildContext context) => MediaQuery.of(context).size.height;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XffF8FA8D),
      appBar: AppBar(
        title: Text('Playlist'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // page  title

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(
                        top: height(context) * 0.10,
                        left: height(context) * 0.10,
                        right: height(context) * 0.05,
                        bottom: height(context) * 0.08),
                    children: _playlistAudioURLs
                        .map((e) => renderSavedPlayListAudioItem(
                            e, context, _currentPlay == e, _scrollController))
                        .toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child: Text(
              'Some Playlist',
              style: TextStyle(
                  fontSize: height(context) * 0.025,
                  fontWeight: FontWeight.bold),
            ),
          ),
          //Audioplayer
          Container(
            child: Column(
              children: [
                SeekBar(
                  barColor: Colors.grey.shade400,
                  progressColor: Colors.black,
                  thumbColor: Colors.black,
                  thumbRadius: 15,
                  onProgressChanged: _onSeekbarChanged,
                  value: _audioProgress,
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        // prev
                        IconButton(
                            onPressed: _currentAudioIndex == 0 ? null : _prev,
                            icon: ImageIcon(AssetImage('images/previous.png')),
                            iconSize: 30.0),

                        // play/pause

                        CircleAvatar(
                          child: IconButton(
                            icon: Icon(
                              _renderPlayPauseIcon(_playerState),
                              color: Colors.white,
                            ),
                            iconSize: 25,
                            onPressed: togglePlay,
                          ),
                        ),

                        CircleAvatar(
                          child: IconButton(
                            icon: ImageIcon(
                              AssetImage('images/shuffle.png'),
                              color: Colors.white,
                            ),
                            iconSize: 30,
                            onPressed: () {
                              print('nothing happens');
                            },
                          ),
                        ),
                        // next
                        IconButton(
                          onPressed: _currentAudioIndex ==
                                  _playlistAudioURLs.length - 1
                              ? null
                              : _next,
                          icon: ImageIcon(AssetImage('images/next.png')),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookAudio {
  final int bookId;
  final String audioURL;

  BookAudio(this.bookId, this.audioURL);
}
