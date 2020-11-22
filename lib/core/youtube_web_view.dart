import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter/platform_interface.dart';
import '../utils/errors.dart';
import '../enums/player_state.dart';
import '../utils/youtube_meta_data.dart';
import '../utils/youtube_player_controller.dart';

class YoutubeWebView extends StatefulWidget {
  /// Sets [Key] as an identification to underlying web view associated to the player.
  final Key key;

  final YoutubePlayerController controller;

  /// {@macro youtube_player.onEnded}
  final void Function(YoutubeMetaData metaData) onEnded;

  /// Creates a [YoutubeWebView] widget.
  YoutubeWebView({this.key, this.onEnded, this.controller});

  @override
  _YoutubeWebViewState createState() => _YoutubeWebViewState();
}

class _YoutubeWebViewState extends State<YoutubeWebView>
    with WidgetsBindingObserver {
  YoutubePlayerController controller;
  PlayerState _cachedPlayerState;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (widget.controller != null && !widget.controller.hasDisposed) {
      this.controller = widget.controller;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_cachedPlayerState != null &&
            _cachedPlayerState == PlayerState.playing) {
          controller?.play();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _cachedPlayerState = controller.value.playerState;
        controller?.pause();
        break;
      default:
    }
  }

  JavascriptChannel _getJavascriptChannel() {
    return JavascriptChannel(
      name: 'YTWebView',
      onMessageReceived: (JavascriptMessage message) {
        Map<String, dynamic> jsonMessage = jsonDecode(message.message);
        switch (jsonMessage['method']) {
          case 'Ready':
            {
              controller.updateValue(
                controller.value.copyWith(isReady: true),
              );
              break;
            }

          case 'StateChange':
            {
              int state = jsonMessage['args']['state'] as int;
              _onPlayerStateChange(state);
              break;
            }

          case 'PlaybackQualityChange':
            {
              String playbackQuality =
                  jsonMessage['args']['playbackQuality'] as String;
              controller.updateValue(
                  controller.value.copyWith(playbackQuality: playbackQuality));
              break;
            }

          case 'PlaybackRateChange':
            {
              final num playbackRate = jsonMessage['args']['playbackRate'];
              controller.updateValue(controller.value
                  .copyWith(playbackRate: playbackRate.toDouble()));
              break;
            }

          case 'Errors':
            {
              int errorCode = jsonMessage['args']['errorCode'] as int;
              controller.updateValue(controller.value.copyWith(
                errorCode: errorCode,
                errorMessage: errorString(
                  errorCode,
                  videoId:
                      controller.metadata.videoId ?? controller.initialVideoId,
                ),
              ));
              break;
            }

          case 'VideoData':
            {
              final rawMetaData = jsonMessage['args'];
              final metaData = YoutubeMetaData.fromRawData(rawMetaData);
              controller
                  .updateValue(controller.value.copyWith(metaData: metaData));
              break;
            }

          case 'VideoTime':
            {
              final position = jsonMessage['args']['position'] * 1000;
              final num buffered = jsonMessage['args']['buffered'];
              controller.updateValue(
                controller.value.copyWith(
                  position: Duration(milliseconds: position.floor()),
                  buffered: buffered.toDouble(),
                ),
              );
              break;
            }
        }
      },
    );
  }

  void _onPlayerStateChange(int state) {
    switch (state) {
      case -1:
        controller.updateValue(controller.value
            .copyWith(isLoaded: true, playerState: PlayerState.unStarted));
        break;
      case 0:
        {
          if (widget.onEnded != null) {
            widget.onEnded(controller.metadata);
          }
          controller.updateValue(controller.value.copyWith(
            playerState: PlayerState.ended,
          ));
          break;
        }
      case 1:
        controller.updateValue(controller.value.copyWith(
          playerState: PlayerState.playing,
          isPlaying: true,
          hasPlayed: true,
          errorMessage: '',
          errorCode: 0,
        ));
        break;
      case 2:
        controller.updateValue(controller.value.copyWith(
          playerState: PlayerState.paused,
          isPlaying: false,
        ));
        break;
      case 3:
        controller.updateValue(controller.value.copyWith(
          playerState: PlayerState.buffering,
        ));
        break;
      case 5:
        controller.updateValue(controller.value.copyWith(
          playerState: PlayerState.cued,
        ));
        break;
      default:
        throw Exception('Invalid player state obtained.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || controller.hasDisposed) {
      controller = YoutubePlayerController.of(context);
    }
    return WebView(
      key: widget.key,
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: _onWebViewCreated,
      onWebResourceError: _handleWebResourceError,
      debuggingEnabled: true,
      initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      javascriptChannels: Set()
        ..add(_getJavascriptChannel()),
      userAgent: userAgent,
    );
  }

  void _onWebViewCreated(WebViewController webViewController) {
    webViewController.loadUrl(
      Uri.dataFromString(
        _buildYoutubeHtml(controller),
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ).toString(),
    );
    controller.updateValue(
        controller.value.copyWith(webViewController: webViewController));
  }

  void _handleWebResourceError(WebResourceError error) {
    controller.updateValue(controller.value.copyWith(
      errorCode: error.errorCode,
      errorMessage: error.description,
    ));
    print(error);
  }

  String _buildYoutubeHtml(YoutubePlayerController controller) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            html,
            body {
                margin: 0;
                padding: 0;
                background-color: #000000;
                overflow: hidden;
                position: fixed;
                height: 100%;
                width: 100%;
                pointer-events: none;
            }
        </style>
        <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
    </head>
    <body>
        <div id="player"></div>
        <script>
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
            var player;
            var timerId;
            function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                    height: '100%',
                    width: '100%',
                    videoId: '${controller.initialVideoId}',
                    playerVars: {
                        'controls': 0,
                        'playsinline': 1,
                        'enablejsapi': 1,
                        'fs': 0,
                        'rel': 0,
                        'showinfo': 0,
                        'iv_load_policy': 3,
                        'modestbranding': 1,
                        'cc_load_policy': ${_boolean(value: controller.flags.enableCaption)},
                        'cc_lang_pref': '${controller.flags.captionLanguage}',
                        'autoplay': ${_boolean(value: controller.flags.autoPlay)},
                        'start': ${controller.flags.startAt},
                        'end': ${controller.flags.endAt}
                    },
                    events: {
                        onReady: function(event) { sendMessageToDart('Ready'); },
                        onStateChange: function(event) { sendPlayerStateChange(event.data); },
                        onPlaybackQualityChange: function(event) { sendMessageToDart('PlaybackQualityChange', {'playbackQuality': event.data}); },
                        onPlaybackRateChange: function(event) { sendMessageToDart('PlaybackRateChange', {'playbackRate': event.data}); },
                        onError: function(error) { sendMessageToDart('Errors', {'errorCode': error.data}); }
                    },
                });
            }
            
            function sendMessageToDart(methodName, argsObject = {}) {
                var message = {
                    'method': methodName,
                    'args': argsObject
                };
                YTWebView.postMessage(JSON.stringify(message));
            }

            function sendPlayerStateChange(playerState) {
                clearTimeout(timerId);
                sendMessageToDart('StateChange', {'state': playerState});
                if (playerState == 1) {
                    startSendCurrentTimeInterval();
                    sendVideoData(player);
                }
            }

            function sendVideoData(player) {
                var videoData = {
                    'duration': player.getDuration(),
                    'title': player.getVideoData().title,
                    'author': player.getVideoData().author,
                    'videoId': player.getVideoData().video_id
                };
                sendMessageToDart('VideoData', videoData);
            }

            function startSendCurrentTimeInterval() {
                timerId = setInterval(function () {
                    sendMessageToDart('VideoTime', {'position': player.getCurrentTime(), 'buffered': player.getVideoLoadedFraction()});
                }, 100);
            }

            function play() {
                player.playVideo();
                return '';
            }

            function pause() {
                player.pauseVideo();
                return '';
            }

            function loadById(loadSettings) {
                player.loadVideoById(loadSettings);
                return '';
            }

            function cueById(cueSettings) {
                player.cueVideoById(cueSettings);
                return '';
            }

            function loadPlaylist(playlist, index, startAt) {
                player.loadPlaylist(playlist, 'playlist', index, startAt);
                return '';
            }

            function cuePlaylist(playlist, index, startAt) {
                player.cuePlaylist(playlist, 'playlist', index, startAt);
                return '';
            }

            function mute() {
                player.mute();
                return '';
            }

            function unMute() {
                player.unMute();
                return '';
            }

            function setVolume(volume) {
                player.setVolume(volume);
                return '';
            }

            function seekTo(position, seekAhead) {
                player.seekTo(position, seekAhead);
                return '';
            }

            function setSize(width, height) {
                player.setSize(width, height);
                return '';
            }

            function setPlaybackRate(rate) {
                player.setPlaybackRate(rate);
                return '';
            }

            function setTopMargin(margin) {
                document.getElementById("player").style.marginTop = margin;
                return '';
            }
        </script>
    </body>
    </html>
  ''';
  }

  int _boolean({@required bool value}) => value ? 1 : 0;

  String get userAgent => controller.flags.forceHD
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
      : null;
}
