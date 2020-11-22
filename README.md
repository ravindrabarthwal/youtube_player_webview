# Important Note
This library is the forked version of youtube_player_flutter. The aim of this fork is to use flutter's official webview instead of third party. Also, the original author kinda left the library hanging with no updates, this is to make sure we can update and fix bugs in this library timely.

![YOUTUBE PLAYER FLUTTER](https://github.com/sarbagyastha/youtube_player_flutter/blob/master/packages/youtube_player_flutter/misc/ypf_banner.png)

[![pub package](https://img.shields.io/pub/vpre/youtube_player_webview.svg)](https://pub.dartlang.org/packages/youtube_player_webview)
[![licence](https://img.shields.io/badge/licence-BSD-orange.svg)](https://github.com/ravindrabarthwal/youtube_player_webview/blob/master/LICENSE)
[![effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://dart.dev/guides/language/effective-dart)


Flutter plugin for playing or streaming YouTube videos inline using the official [**iFrame Player API**](https://developers.google.com/youtube/iframe_api_reference).

Supported Platforms:
* **Android** 
* **iOS**

![DEMO](https://github.com/sarbagyastha/youtube_player_flutter/blob/master/packages/youtube_player_flutter/misc/ypf_demo.gif)

## Salient Features
* Inline Playback
* Supports captions
* No need for API Key
* Supports custom controls
* Retrieves video meta data
* Supports Live Stream videos
* Supports changing playback rate
* Support for both Android and iOS
* Adapts to quality as per the bandwidth
* Fast Forward and Rewind on horizontal drag
* Fit Videos to wide screens with pinch gestures

The plugin uses [webview_flutter](https://pub.dartlang.org/packages/webview_flutter) under-the-hood.

## Requirements
* Android: `minSdkVersion 17` and add support for `androidx` (see [AndroidX Migration](https://flutter.dev/docs/development/androidx-migration))
* iOS: `--ios-language swift`, Xcode version `>= 11`

## Setup

### iOS
Add these lines to `Info.plist`

```xml
<key>io.flutter.embedded_views_preview</key>
<true/>
```

For more info, [see here](https://pub.dev/packages/flutter_inappwebview#important-note-for-ios)

### Android
Set `minSdkVersion` of your `android/app/build.gradle` file to at least 17.

For more info, [see here](https://pub.dev/packages/flutter_inappwebview#important-note-for-android)

*Note:* Although the minimum to be set is 17, the player won't play on device with API < 20. 
For API < 20 devices, you might want to forward the video to be played using YouTube app instead, using packages like `url_launcher` or `android_intent`.

#### Using Youtube Player
         
```dart
YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: 'iLnmTe5Q2Qw',
    flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
    ),
);

YoutubePlayer(
    controller: _controller,
    showVideoProgressIndicator: true,
    videoProgressIndicatorColor: Colors.amber,
    progressColors: ProgressColors(
        playedColor: Colors.amber,
        handleColor: Colors.amberAccent,
    ),
    onReady () {
        _controller.addListener(listener);
    },
),
```

#### For FullScreen Support
If fullscreen support is required, wrap your player with `YoutubePlayerBuilder`

```dart
YoutubePlayerBuilder(
    player: YoutubePlayer(
        controller: _controller,
    ),
    builder: (context, player){
        return Column(
            children: [
                // some widgets
                player,
                //some other widgets
            ],
        );
    ),
),
```

         
#### Playing live stream videos
Set the isLive property to true in order to change the UI to match Live Video.

![Live UI Demo](https://github.com/sarbagyastha/youtube_player_flutter/blob/master/packages/youtube_player_flutter/misc/live_ui.png)

```dart
YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: 'iLnmTe5Q2Qw',
    flags: YoutubePLayerFlags(
      isLive: true,
    ),
);

YoutubePlayer(
    controller: _controller,
    liveUIColor: Colors.amber,
),
```

## Want to customize the player?
 With v5.x.x and up, use the `topActions` and `bottomActions` properties to customize the player.

 Some of the widgets bundled with the plugin are:
 * FullScreenButton
 * RemainingDuration
 * CurrentPosition
 * PlayPauseButton
 * PlaybackSpeedButton
 * ProgressBar

```dart
YoutubePlayer(
    controller: _controller,
    bottomActions: [
      CurrentPosition(),
      ProgressBar(isExpanded: true),
      TotalDuration(),
    ],
),
```

## Want to play using Youtube URLs ? 
The plugin also provides `convertUrlToId()` method that converts youtube links to its corresponding video ids.
```dart
String videoId;
videoId = YoutubePlayer.convertUrlToId("https://www.youtube.com/watch?v=BBAyRBTfsOU");
print(videoId); // BBAyRBTfsOU
```

## Example

[Detailed Example](https://github.com/ravindrabarthwal/youtube_player_webview/tree/master/example)


## Limitation 
Since the plugin is based on platform views. This plugin requires Android API level 20 or greater.


## License

```
Copyright 2020 Sarbagya Dhaubanjar (original author) & Ravindra Barthwal (forker of this version). All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
