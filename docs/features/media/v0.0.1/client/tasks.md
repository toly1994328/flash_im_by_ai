# fx_media 鈥?瀹㈡埛绔换鍔℃竻鍗?

鍩轰簬 client/design.md 璁捐锛屽垪鍑洪渶瑕佸垱寤?淇敼鐨勫叿浣撶粏鑺傘€?

鍏ㄥ眬绾︽潫锛?
- fx_media 鍖呬笉渚濊禆浠讳綍闂涓氬姟妯″瀷锛圡essage銆丆onversation 绛夛級
- fx_media 鍖呬笉鐩存帴渚濊禆 dio锛岄€氳繃 typedef 娉ㄥ叆涓嬭浇鍑芥暟
- 鏃ュ織浣跨敤 fx_logger锛歚final _log = FxLog('Tag')`
- 鍙橀噺蹇呴』鏄惧紡鏍囨敞绫诲瀷
- 杩佺Щ鍚?CloudDownloadManager 鍜?VideoPlayerPage锛坒lash_im_chat锛夊垹闄?

---

## 鎵ц椤哄簭

1. 鉁?浠诲姟 1 鈥?fx_media 鍖呴鏋讹紙pubspec + barrel export + FxMedia 鍏ュ彛锛?
2. 鉁?浠诲姟 2 鈥?涓嬭浇浜嬩欢妯″瀷锛團xDownloadEvent sealed class锛?
3. 鉁?浠诲姟 3 鈥?涓嬭浇绠＄悊瀹炵幇锛團xMediaDownload + 闃熷垪 + 骞跺彂 + 鍘婚噸锛?
4. 鉁?浠诲姟 4 鈥?闊抽鐘舵€佹ā鍨?+ 鍏ㄥ眬闊抽鎾斁鍣ㄥ疄鐜?
5. 鉁?浠诲姟 5 鈥?鍥剧墖妯″潡锛團xMediaImage + FxCachedImage Widget锛?
6. 鉁?浠诲姟 6 鈥?瑙嗛妯″潡锛團xMediaVideo + 鍏ㄥ睆鎾斁椤碉級
7. 鉁?浠诲姟 7 鈥?鏂囦欢妯″潡锛團xMediaFile锛氭墦寮€/鍙﹀瓨涓?鎵撳紑鏂囦欢澶癸級
8. 鉁?浠诲姟 8 鈥?涓诲簲鐢ㄩ泦鎴愶紙pubspec 渚濊禆 + main.dart 鍒濆鍖栵級
9. 鉁?浠诲姟 9 鈥?杩佺Щ ChatMediaHandler
10. 鉁?浠诲姟 10 鈥?杩佺Щ AudioBubble
11. 鉁?浠诲姟 11 鈥?杩佺Щ ImageBubble
12. 鉁?浠诲姟 12 鈥?杩佺Щ ChatCubit / chat_file_mixin
13. 鉁?浠诲姟 13 鈥?杩佺Щ flash_cloud锛團ileDetailCubit锛?
14. 鉁?浠诲姟 14 鈥?鍒犻櫎搴熷純鏂囦欢 + 娓呯悊瀵煎嚭
15. 鉁?浠诲姟 15 鈥?缂栬瘧楠岃瘉

---

## 浠诲姟 1锛氬寘楠ㄦ灦 `鉁?宸插畬鎴恅

鏂囦欢锛歚client/packages/fx_media/pubspec.yaml`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/fx_media.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/fx_media_init.dart`锛堟柊寤猴級

### 1.1 pubspec.yaml `猬渀

```yaml
name: fx_media
description: 閫氱敤濯掍綋绠＄悊鍖咃紙涓嬭浇/缂撳瓨/鎾斁/棰勮/鎵撳紑锛?
version: 0.0.1

environment:
  sdk: ^3.6.0
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  fx_logger:
    path: ../fx_logger
  just_audio: ^0.9.43
  video_player: ^2.9.3
  flutter_cache_manager: ^3.4.1
  cached_network_image: ^3.4.1
  tolyui_mediax_core: ^0.1.0
  tolyui_mediax_ui: ^0.1.0
  file_picker: ^8.3.7
  open_file: ^3.5.10
  path: ^1.9.1
```

娉細tolyui_mediax_core 鍜?tolyui_mediax_ui 浣跨敤椤圭洰宸叉湁鐨?dependency_overrides 鎸囧悜鏈湴璺緞銆?

### 1.2 barrel export锛坒x_media.dart锛?`猬渀

瀵煎嚭鎵€鏈夊叕寮€ API锛?

```dart
library;

export 'src/fx_media_init.dart';
export 'src/download/fx_download_event.dart';
export 'src/download/fx_media_download.dart';
export 'src/audio/fx_audio_state.dart';
export 'src/audio/fx_media_audio.dart';
export 'src/image/fx_media_image.dart';
export 'src/image/fx_cached_image.dart';
export 'src/video/fx_media_video.dart';
export 'src/file/fx_media_file.dart';
```

### 1.3 FxMedia 鍏ュ彛绫伙紙fx_media_init.dart锛?`猬渀

```dart
typedef FxDownloadFunction = Future<void> Function(
  String url,
  String savePath, {
  void Function(double progress)? onProgress,
});

class FxMedia {
  static late final FxMediaDownload download;
  static late final FxMediaAudio audio;
  static late final FxMediaImage image;
  static late final FxMediaVideo video;
  static late final FxMediaFile file;

  static bool _initialized = false;

  static void init({
    required String cacheDir,
    required FxDownloadFunction downloadFn,
    int maxConcurrent = 5,
  });
  // 閫昏緫锛?
  // 1. 鏂█ !_initialized 闃叉閲嶅鍒濆鍖?
  // 2. 鍒涘缓鍚勫瓙妯″潡瀹炰緥锛岃祴鍊肩粰 static late final
  // 3. _initialized = true
}
```

---

## 浠诲姟 2锛氫笅杞戒簨浠舵ā鍨?`鉁?宸插畬鎴恅

鏂囦欢锛歚client/packages/fx_media/lib/src/download/fx_download_event.dart`锛堟柊寤猴級

### 2.1 sealed class 瀹氫箟 `猬渀

```dart
sealed class FxDownloadEvent {
  final String id;
  final String url;
  const FxDownloadEvent({required this.id, required this.url});
}

class FxDownloadProgress extends FxDownloadEvent {
  final double progress;
  const FxDownloadProgress({required super.id, required super.url, required this.progress});
}

class FxDownloadComplete extends FxDownloadEvent {
  final String localPath;
  const FxDownloadComplete({required super.id, required super.url, required this.localPath});
}

class FxDownloadError extends FxDownloadEvent {
  final Object error;
  const FxDownloadError({required super.id, required super.url, required this.error});
}
```

---

## 浠诲姟 3锛氫笅杞界鐞嗗疄鐜?`鉁?宸插畬鎴恅

鏂囦欢锛歚client/packages/fx_media/lib/src/download/fx_media_download.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/download/fx_media_download_impl.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/download/download_task.dart`锛堟柊寤猴級

### 3.1 鎶借薄鎺ュ彛锛坒x_media_download.dart锛?`猬渀

```dart
abstract class FxMediaDownload {
  Stream<FxDownloadEvent> stream({required String url, String? id, String? fileName});
  Future<String> get({required String url, String? id, String? fileName});
  bool isCached(String id);
  String? localPath(String id);
  Future<void> remove(String id);
  void cancel(String id);
}
```

### 3.2 鍐呴儴浠诲姟妯″瀷锛坉ownload_task.dart锛?`猬渀

涓嶅鍑猴紝浠呭唴閮ㄤ娇鐢細

```dart
class DownloadTask {
  final String id;
  final String url;
  final String? fileName;
  final StreamController<FxDownloadEvent> controller;
  bool cancelled = false;

  DownloadTask({required this.id, required this.url, this.fileName, required this.controller});
}
```

### 3.3 瀹炵幇绫伙紙fx_media_download_impl.dart锛?`猬渀

```dart
class FxMediaDownloadImpl implements FxMediaDownload {
  final FxDownloadFunction _downloadFn;
  final String _cacheDir;
  final int _maxConcurrent;

  /// id 鈫?localPath 缂撳瓨鏄犲皠锛堝唴瀛橈級
  final Map<String, String> _cacheMap = {};
  /// id 鈫?姝ｅ湪杩涜鐨勪笅杞?StreamController锛堝幓閲嶏級
  final Map<String, StreamController<FxDownloadEvent>> _activeStreams = {};
  /// 绛夊緟闃熷垪
  final Queue<DownloadTask> _queue = Queue();
  /// 褰撳墠娲昏穬涓嬭浇鏁?
  int _activeCount = 0;

  FxMediaDownloadImpl({
    required FxDownloadFunction downloadFn,
    required String cacheDir,
    required int maxConcurrent,
  });
}
```

鏍稿績閫昏緫姝ラ锛坰tream 鏂规硶锛夛細
1. id 涓虹┖鏃跺彇 url 浣滀负 id
2. 妫€鏌?`_cacheMap[id]` 鈫?鍛戒腑涓旀枃浠跺瓨鍦?鈫?鐩存帴鍙?Complete 鍏抽棴
3. 妫€鏌?`_activeStreams[id]` 鈫?鏈夊垯杩斿洖宸叉湁 stream
4. 鍒涘缓 DownloadTask锛岃绠?savePath = `_cacheDir/{category}/{id}{ext}`
5. 骞跺彂妫€鏌ワ細`_activeCount < _maxConcurrent` 鈫?鍚姩锛涘惁鍒欏叆闃熷垪
6. 涓嬭浇瀹屾垚鍚庯細鏇存柊 `_cacheMap`锛屼粠 `_activeStreams` 绉婚櫎锛屽彂 Complete锛屾鏌ラ槦鍒?

savePath 鎺ㄥ锛?
- 浠?fileName 鎴?url 鎻愬彇鎵╁睍鍚?
- 璺緞鏍煎紡锛歚{_cacheDir}/{id}{ext}`锛堢敤 id 鍋氭枃浠跺悕锛屼繚璇佸敮涓€锛?

cancel 鏂规硶锛?
- 鏍囪 task.cancelled = true
- 濡傛灉鍦ㄩ槦鍒椾腑 鈫?绉婚櫎
- 濡傛灉姝ｅ湪涓嬭浇 鈫?鍙?Error 浜嬩欢锛屽叧闂?stream锛堜笅杞藉嚱鏁板唴閮ㄩ潬 cancelled 鏍囧織鎻愬墠缁堟锛?

---

## 浠诲姟 4锛氶煶棰戞ā鍧?`鉁?宸插畬鎴恅

鏂囦欢锛歚client/packages/fx_media/lib/src/audio/fx_audio_state.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/audio/fx_media_audio.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/audio/fx_media_audio_impl.dart`锛堟柊寤猴級

### 4.1 鐘舵€佹ā鍨嬶紙fx_audio_state.dart锛?`猬渀

```dart
enum FxAudioState { idle, loading, playing, paused, completed, error }

class FxAudioSnapshot {
  final FxAudioState state;
  final String? currentId;
  final Duration position;
  final Duration duration;

  const FxAudioSnapshot({
    this.state = FxAudioState.idle,
    this.currentId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
}
```

### 4.2 鎶借薄鎺ュ彛锛坒x_media_audio.dart锛?`猬渀

```dart
abstract class FxMediaAudio {
  Future<void> play(String url, {String? id});
  Future<void> playFile(String localPath, {String? id});
  Future<void> pause();
  Future<void> stop();
  String? get currentId;
  Stream<FxAudioSnapshot> get snapshotStream;
  void dispose();
}
```

### 4.3 瀹炵幇绫伙紙fx_media_audio_impl.dart锛?`猬渀

```dart
class FxMediaAudioImpl implements FxMediaAudio {
  final AudioPlayer _player = AudioPlayer();
  String? _currentId;
  final StreamController<FxAudioSnapshot> _snapshotController = StreamController.broadcast();
}
```

鏍稿績閫昏緫锛?
1. `play(url, {id})` 鈫?濡傛灉 `_currentId != id`锛屽厛 stop 鍐?setUrl + play
2. `playFile(path, {id})` 鈫?鍚屼笂锛岀敤 setFilePath
3. 鐩戝惉 `_player.playerStateStream` + `_player.positionStream` 鈫?缁勫悎鍙戝皠 FxAudioSnapshot
4. 鎾畬鑷姩鍙?`completed`锛屼笉 dispose player锛堝鐢ㄥ疄渚嬶級
5. `dispose()` 鈫?鍏?player + 鍏?controller

---

## 浠诲姟 5锛氬浘鐗囨ā鍧?`鉁?宸插畬鎴恅

鏂囦欢锛歚client/packages/fx_media/lib/src/image/fx_media_image.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/image/fx_media_image_impl.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/image/fx_cached_image.dart`锛堟柊寤猴級

### 5.1 鎶借薄鎺ュ彛锛坒x_media_image.dart锛?`猬渀

```dart
abstract class FxMediaImage {
  void preview(
    BuildContext context, {
    required List<ImageMeta> items,
    int initialIndex = 0,
    VoidCallback? onDismiss,
  });

  Widget cached({
    required String url,
    String? id,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Map<String, String>? headers,
    void Function(String localPath)? onCached,
  });
}
```

### 5.2 瀹炵幇绫伙紙fx_media_image_impl.dart锛?`猬渀

- `preview`锛氬鍒跺綋鍓?ChatMediaHandler.openImage 鐨?Navigator.push 閫昏緫锛屼娇鐢?MediaPreviewPage + ImageViewer
- `cached`锛氳繑鍥?FxCachedImage Widget

### 5.3 FxCachedImage Widget锛坒x_cached_image.dart锛?`猬渀

```dart
class FxCachedImage extends StatefulWidget {
  final String url;
  final String? id;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Map<String, String>? headers;
  final void Function(String localPath)? onCached;
  // ...
}
```

鏍稿績閫昏緫锛圫tate锛夛細
1. build 鐢?CachedNetworkImage 娓叉煋锛宑acheManager 鐢?PersistentCacheManager 椋庢牸锛坰talePeriod 365 澶╋級
2. 鍥剧墖鍔犺浇瀹屾垚鍚庯紙imageBuilder 鎴?didUpdateWidget锛夛紝璋冪敤 `cacheManager.getFileFromCache(url)` 鑾峰彇璺緞
3. 鑾峰彇鍒拌矾寰勫悗璋冪敤 `onCached?.call(localPath)`
4. 鐢?`_hasCalled` 鏍囧織浣嶉槻姝㈤噸澶嶅洖璋?

---

## 浠诲姟 6锛氳棰戞ā鍧?`鉁?宸插畬鎴恅

鏂囦欢锛歚client/packages/fx_media/lib/src/video/fx_media_video.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/video/fx_media_video_impl.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/video/fx_video_player_page.dart`锛堟柊寤猴級

### 6.1 鎶借薄鎺ュ彛锛坒x_media_video.dart锛?`猬渀

```dart
abstract class FxMediaVideo {
  void open(BuildContext context, String url);
  void openFile(BuildContext context, String localPath);
}
```

### 6.2 瀹炵幇绫伙紙fx_media_video_impl.dart锛?`猬渀

- `open` 鈫?Navigator.push 鈫?FxVideoPlayerPage(source: NetworkSource)
- `openFile` 鈫?Navigator.push 鈫?FxVideoPlayerPage(source: FileSource)

### 6.3 鍏ㄥ睆鎾斁椤碉紙fx_video_player_page.dart锛?`猬渀

鍩轰簬鐜版湁 VideoPlayerPage 鏀归€狅細

```dart
class FxVideoPlayerPage extends StatefulWidget {
  final String source;    // URL 鎴栨湰鍦拌矾寰?
  final bool isLocal;
}
```

鏀瑰姩鐐癸細
- initState 涓牴鎹?`isLocal` 閫夋嫨 `VideoPlayerController.file(File(source))` 鎴?`VideoPlayerController.networkUrl(Uri.parse(source))`
- 鎺у埗鏉′繚鎸佺幇鏈夋牱寮忎笉鍙?
- 鍏朵綑閫昏緫涓庢棫 VideoPlayerPage 涓€鑷?

---

## 浠诲姟 7锛氭枃浠舵ā鍧?`鉁?宸插畬鎴恅

鏂囦欢锛歚client/packages/fx_media/lib/src/file/fx_media_file.dart`锛堟柊寤猴級
鏂囦欢锛歚client/packages/fx_media/lib/src/file/fx_media_file_impl.dart`锛堟柊寤猴級

### 7.1 鎶借薄鎺ュ彛锛坒x_media_file.dart锛?`猬渀

```dart
abstract class FxMediaFile {
  Future<void> open(String localPath);
  Future<void> saveAs(String localPath, {String? suggestedName});
  Future<void> openFolder(String localPath);
}
```

### 7.2 瀹炵幇绫伙紙fx_media_file_impl.dart锛?`猬渀

鏍稿績閫昏緫锛?

- `open`锛?
  - 妗岄潰绔細`Process.start('cmd', ['/c', 'start', '', localPath])`锛圵indows锛夛紝`Process.run('open', [localPath])`锛坢acOS锛?
  - 绉诲姩绔細浣跨敤 `open_file` 鍖呯殑 `OpenFile.open(localPath)`

- `saveAs`锛?
  - 璋冪敤 `FilePicker.platform.saveFile(dialogTitle: '鍙﹀瓨涓?, fileName: suggestedName ?? basename)`
  - 鐢ㄦ埛閫変簡璺緞鍚?`File(localPath).copy(outputPath)`

- `openFolder`锛?
  - Windows锛歚Process.start('explorer.exe', ['/select,$normalizedPath'])`
  - macOS锛歚Process.run('open', ['-R', localPath])`
  - Linux锛歚Process.run('xdg-open', [parentDir])`
  - 绉诲姩绔細no-op锛堢Щ鍔ㄧ鏃犳姒傚康锛?

---

## 浠诲姟 8锛氫富搴旂敤闆嗘垚 `鉁?宸插畬鎴恅

鏂囦欢锛歚client/pubspec.yaml`锛堜慨鏀癸級
鏂囦欢锛歚client/lib/main.dart`锛堜慨鏀癸級

### 8.1 pubspec.yaml 娣诲姞渚濊禆 `猬渀

```yaml
dependencies:
  fx_media:
    path: packages/fx_media
```

### 8.2 main.dart 鍒濆鍖?`猬渀

鍦ㄧ幇鏈?`CloudDownloadManager().init(...)` 浣嶇疆鏇挎崲涓猴細

```dart
import 'package:fx_media/fx_media.dart';

// 鑾峰彇 cacheDir
final Directory cacheDir = await getApplicationCacheDirectory();
final String mediaCacheDir = '${cacheDir.path}/fx_media';

FxMedia.init(
  cacheDir: mediaCacheDir,
  downloadFn: (String url, String savePath, {void Function(double)? onProgress}) async {
    await httpClient.dio.download(url, savePath, onReceiveProgress: (int count, int total) {
      if (total > 0 && onProgress != null) {
        onProgress(count / total);
      }
    });
  },
  maxConcurrent: 5,
);
```

鍒犻櫎 `CloudDownloadManager().init(...)` 閭ｄ竴琛屻€?

---

## 浠诲姟 9锛氳縼绉?ChatMediaHandler `鉁?宸插畬鎴恅

鏂囦欢锛歚client/modules/flash_im_chat/lib/src/logic/handler/chat_media_handler.dart`锛堜慨鏀癸級

### 9.1 鏇挎崲鍥剧墖棰勮 `猬渀

- 鍒犻櫎 openImage 鍐呴儴鐨?Navigator.push + MediaPreviewPage 鏋勫缓閫昏緫
- 鏀逛负锛?

```dart
void openImage(BuildContext context, Message msg, {List<Message>? imageMessages, int? index}) {
  final List<ImageMeta> items = (imageMessages ?? [msg])
      .map((m) => m.toImageMeta(baseUrl: baseUrl ?? ''))
      .toList();
  FxMedia.image.preview(context, items: items, initialIndex: index ?? 0);
}
```

### 9.2 鏇挎崲瑙嗛鎵撳紑 `猬渀

- 鍒犻櫎鏃х殑鏉′欢鍒ゆ柇閫昏緫锛堟闈㈢ Process.start / 绉诲姩绔?VideoPlayerPage锛?
- 鏀逛负锛?

```dart
Future<void> openVideo(BuildContext context, Message msg) async {
  final String? cachedPath = extractLocalPath(msg);
  if (cachedPath != null && File(cachedPath).existsSync()) {
    // 宸茬紦瀛?
    if (kApp.isDesktop) {
      await FxMedia.file.open(cachedPath);
    } else {
      FxMedia.video.openFile(context, cachedPath);
    }
  } else {
    // 鏈紦瀛橈細涓嬭浇鍚庢墦寮€
    final String videoUrl = _fullUrl(msg.content);
    final String localPath = await FxMedia.download.get(url: videoUrl, id: msg.id);
    _cubit.updateMessageLocalData(msg.id, localPath);
    if (!context.mounted) return;
    if (kApp.isDesktop) {
      await FxMedia.file.open(localPath);
    } else {
      FxMedia.video.openFile(context, localPath);
    }
  }
}
```

### 9.3 鏇挎崲鏂囦欢鎿嶄綔 `猬渀

- `openFile`锛氭闈㈢涓嬭浇閮ㄥ垎鏀圭敤 `FxMedia.download.get` + `FxMedia.file.open`
- `openFileFolder`锛氭敼涓?`FxMedia.file.openFolder(localPath)`
- `saveFileAs`锛氭敼涓?`FxMedia.file.saveAs(localPath, suggestedName: fileName)`

### 9.4 娓呯悊 import `猬渀

- 鍒犻櫎 `import 'package:flash_im_cache/flash_im_cache.dart' show FileCacheManager, FileCategory`
- 鍒犻櫎 `import '../../view/media/video_player_page.dart'`
- 娣诲姞 `import 'package:fx_media/fx_media.dart'`

---

## 浠诲姟 10锛氳縼绉?AudioBubble `鉁?宸插畬鎴恅

鏂囦欢锛歚client/modules/flash_im_chat/lib/src/view/bubble/audio_bubble.dart`锛堜慨鏀癸級

### 10.1 鍘绘帀鍐呴儴 AudioPlayer `猬渀

- 鍒犻櫎 `final AudioPlayer _player = AudioPlayer()` 鍜?initState 涓殑 playerStateStream 鐩戝惉
- 鍒犻櫎 dispose 涓殑 `_player.dispose()`
- 鍒犻櫎 `_togglePlay` 涓殑 player 鎿嶄綔

### 10.2 鏀圭敤 FxMedia.audio `猬渀

```dart
class _AudioBubbleState extends State<AudioBubble> {
  StreamSubscription<FxAudioSnapshot>? _sub;

  String get _audioId => widget.message.id;

  bool get _isPlaying {
    return FxMedia.audio.currentId == _audioId;
    // 绮剧‘鐘舵€佺敱 snapshotStream 椹卞姩 rebuild
  }

  @override
  void initState() {
    super.initState();
    _sub = FxMedia.audio.snapshotStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (FxMedia.audio.currentId == _audioId) {
      // 褰撳墠姝ｅ湪鎾斁杩欐潯 鈫?鏆傚仠/鎭㈠
      await FxMedia.audio.pause();
    } else {
      final String url = _audioUrl;
      if (_isLocalFile) {
        await FxMedia.audio.playFile(url, id: _audioId);
      } else {
        await FxMedia.audio.play(url, id: _audioId);
      }
    }
  }
}
```

### 10.3 鏇存柊 import `猬渀

- 鍒犻櫎 `import 'package:just_audio/just_audio.dart'`
- 娣诲姞 `import 'package:fx_media/fx_media.dart'`

---

## 浠诲姟 11锛氳縼绉?ImageBubble `鉁?宸插畬鎴恅

鏂囦欢锛歚client/modules/flash_im_chat/lib/src/view/bubble/image_bubble.dart`锛堜慨鏀癸級

### 11.1 宸插彂閫佸浘鐗囨敼鐢?FxMedia.image.cached `猬渀

褰撳墠宸插彂閫佺姸鎬佺敤 `MediaImageView`锛屾敼涓猴細

```dart
// 宸插彂閫侊細鐢?FxMedia.image.cached锛堣嚜鍔ㄧ紦瀛?+ 鍥炶皟璺緞锛?
Widget _buildNetworkImage(ImageMeta meta, double width, double height, bool crop) {
  final String url = switch (meta.source) {
    NetworkSource(:final uri) => uri.toString(),
    _ => '',
  };
  if (url.isEmpty) return _buildFromMeta(meta, width, height, crop);

  return GestureDetector(
    onTap: onTap,
    child: Hero(
      tag: meta.heroTag ?? meta.hashCode,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1A000000), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FxMedia.image.cached(
            url: url,
            id: message.id,
            fit: BoxFit.cover,
            width: width,
            height: height,
            onCached: (String localPath) {
              // 閫氱煡涓氬姟灞傛洿鏂?localData
              // 閫氳繃鍥炶皟浼犲嚭鍘伙紝鐢?ChatPage 灞傚鐞?
            },
          ),
        ),
      ),
    ),
  );
}
```

娉ㄦ剰锛氬鏋?meta.source 鏄?FileSource锛堟湰鍦板凡鏈夛級锛屼繚鎸佺幇鏈?Image.file 閫昏緫涓嶅彉銆傚彧鏈?NetworkSource 鎵嶈蛋 FxMedia.image.cached銆?

### 11.2 娣诲姞 onCached 鍥炶皟鍙傛暟 `猬渀

ImageBubble 鏂板鍙€夊弬鏁帮細

```dart
final void Function(String messageId, String localPath)? onCached;
```

鍦?FxMedia.image.cached 鐨?onCached 涓皟鐢細`widget.onCached?.call(widget.message.id, localPath)`

### 11.3 鏇存柊 import `猬渀

- 娣诲姞 `import 'package:fx_media/fx_media.dart'`

---

## 浠诲姟 12锛氳縼绉?ChatCubit / chat_file_mixin `鉁?宸插畬鎴恅

鏂囦欢锛歚client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`锛堜慨鏀癸級
鏂囦欢锛歚client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`锛堜慨鏀癸級

### 12.1 chat_file_mixin锛歞ownloadFile 鏀圭敤 FxMedia.download `猬渀

```dart
Future<void> downloadFile(String messageId, String fullUrl, String fileName) async {
  // ...鐘舵€佹鏌ヤ笉鍙?..
  _emitDownloadUpdate(messageId, const FileDownloadInfo(status: FileDownloadStatus.downloading));

  try {
    final String localPath = await FxMedia.download.get(url: fullUrl, id: messageId, fileName: fileName);
    _emitDownloadUpdate(messageId, FileDownloadInfo(
      status: FileDownloadStatus.done, progress: 1.0, localPath: localPath,
    ));
    _updateLocalDataInState(messageId, localPath);
  } catch (e) {
    _emitDownloadUpdate(messageId, FileDownloadInfo(
      status: FileDownloadStatus.error, error: e.toString(),
    ));
  }
}
```

娉ㄦ剰锛氬綋鍓?downloadFile 娌℃湁杩涘害鍥炶皟浜嗭紙FxMedia.download.get 鍙繑鍥炴渶缁堢粨鏋滐級銆傚鏋滈渶瑕佽繘搴︼紝鏀圭敤 stream 鏂瑰紡锛?

```dart
FxMedia.download.stream(url: fullUrl, id: messageId, fileName: fileName).listen((event) {
  switch (event) {
    case FxDownloadProgress(:final progress):
      _emitDownloadUpdate(messageId, FileDownloadInfo(status: FileDownloadStatus.downloading, progress: progress));
    case FxDownloadComplete(:final localPath):
      _emitDownloadUpdate(messageId, FileDownloadInfo(status: FileDownloadStatus.done, progress: 1.0, localPath: localPath));
      _updateLocalDataInState(messageId, localPath);
    case FxDownloadError(:final error):
      _emitDownloadUpdate(messageId, FileDownloadInfo(status: FileDownloadStatus.error, error: error.toString()));
  }
});
```

鎺ㄨ崘浣跨敤 stream 鏂瑰紡淇濈暀杩涘害銆?

### 12.2 chat_cubit锛歘autoCacheImages 鏀圭敤 FxMedia.download `猬渀

褰撳墠 `_autoCacheImages` 璋冪敤 `_fileCacheManager.getFile()` 棰勭紦瀛樺浘鐗?瑙嗛灏侀潰/闊抽銆傛敼涓猴細

```dart
void _autoCacheImages(List<Message> messages) {
  for (final Message msg in messages) {
    if (msg.localData != null) continue; // 宸叉湁鏈湴鏁版嵁璺宠繃
    final String url = _buildFullUrl(msg.content);

    switch (msg.type) {
      case MessageType.image:
        FxMedia.download.get(url: url, id: msg.id).then((String path) {
          updateMessageLocalData(msg.id, path);
        }).catchError((_) {});
      case MessageType.video:
        final String? thumbUrl = msg.extra?['thumbnail_url'] as String?;
        if (thumbUrl != null) {
          FxMedia.download.get(url: _buildFullUrl(thumbUrl), id: '${msg.id}_thumb').catchError((_) {});
        }
      case MessageType.audio:
        FxMedia.download.get(url: url, id: msg.id).then((String path) {
          updateMessageLocalData(msg.id, path);
        }).catchError((_) {});
      default:
        break;
    }
  }
}
```

### 12.3 chat_cubit锛氱Щ闄?fileCacheManager 鍙傛暟 `猬渀

- 鍒犻櫎鏋勯€犲弬鏁?`FileCacheManager? fileCacheManager`
- 鍒犻櫎瀛楁 `final FileCacheManager? _fileCacheManager`
- 鍒犻櫎 getter `FileCacheManager? get fileCacheManager`
- chat_file_mixin 涓垹闄?`fileCacheManager` 鎶借薄 getter
- 鎵€鏈夊垱寤?ChatCubit 鐨勫湴鏂瑰垹闄?`fileCacheManager: xxx` 鍙傛暟

### 12.4 鏇存柊 import `猬渀

- 鍒犻櫎 `import 'package:flash_im_cache/flash_im_cache.dart' show FileCacheManager, FileCategory`
- 娣诲姞 `import 'package:fx_media/fx_media.dart'`

---

## 浠诲姟 13锛氳縼绉?flash_cloud `鉁?宸插畬鎴恅

鏂囦欢锛歚client/modules/flash_cloud/lib/src/logic/file_detail_cubit.dart`锛堜慨鏀癸級
鏂囦欢锛歚client/modules/flash_cloud/lib/flash_cloud.dart`锛堜慨鏀癸級
鏂囦欢锛歚client/modules/flash_cloud/pubspec.yaml`锛堜慨鏀癸級

### 13.1 FileDetailState 鏀圭敤 FxDownloadEvent 椋庢牸 `猬渀

褰撳墠 State 涓湁 `DownloadInfo downloadInfo`銆傛敼涓烘洿绠€鍗曠殑瀛楁锛?

```dart
class FileDetailState {
  final FileDetailStatus status;
  final CloudFileDetail? detail;
  final double downloadProgress;    // 0.0 ~ 1.0
  final String? localPath;          // 涓嬭浇瀹屾垚鍚庣殑璺緞
  final bool isDownloading;
  final String? error;

  bool get isCached => localPath != null;
  // ...
}
```

### 13.2 FileDetailCubit 鏀圭敤 FxMedia.download `猬渀

```dart
class FileDetailCubit extends Cubit<FileDetailState> {
  StreamSubscription<FxDownloadEvent>? _downloadSub;

  /// 涓嬭浇鏂囦欢
  void downloadToLocal() {
    if (state.detail == null) return;
    final String url = state.detail!.file.url;
    final String id = state.detail!.file.id.toString();

    emit(state.copyWith(isDownloading: true, downloadProgress: 0.0));

    _downloadSub = FxMedia.download.stream(url: url, id: id).listen((FxDownloadEvent event) {
      switch (event) {
        case FxDownloadProgress(:final progress):
          emit(state.copyWith(downloadProgress: progress));
        case FxDownloadComplete(:final localPath):
          emit(state.copyWith(isDownloading: false, downloadProgress: 1.0, localPath: localPath));
        case FxDownloadError(:final error):
          emit(state.copyWith(isDownloading: false, error: error.toString()));
      }
    });
  }

  /// 鍔犺浇璇︽儏鏃舵鏌ョ紦瀛?
  Future<void> loadDetail(int fileId) async {
    // ...鍔犺浇璇︽儏...
    final String id = fileId.toString();
    final String? cached = FxMedia.download.localPath(id);
    emit(FileDetailState(
      status: FileDetailStatus.loaded,
      detail: detail,
      localPath: cached,
    ));
  }

  /// 娓呴櫎缂撳瓨
  Future<void> clearLocalCache() async {
    if (state.detail == null) return;
    final String id = state.detail!.file.id.toString();
    await FxMedia.download.remove(id);
    emit(state.copyWith(localPath: null));
  }
}
```

### 13.3 flash_cloud barrel 绉婚櫎 CloudDownloadManager 瀵煎嚭 `猬渀

```dart
// 鍒犻櫎杩欒锛?
// export 'src/data/cloud_download_manager.dart';
```

### 13.4 pubspec.yaml 娣诲姞 fx_media 渚濊禆 `猬渀

```yaml
dependencies:
  fx_media:
    path: ../../packages/fx_media
```

---

## 浠诲姟 14锛氬垹闄ゅ簾寮冩枃浠?+ 娓呯悊 `鉁?宸插畬鎴恅

### 14.1 鍒犻櫎 CloudDownloadManager `猬渀

鍒犻櫎鏂囦欢锛歚client/modules/flash_cloud/lib/src/data/cloud_download_manager.dart`

### 14.2 鍒犻櫎鏃?VideoPlayerPage `猬渀

鍒犻櫎鏂囦欢锛歚client/modules/flash_im_chat/lib/src/view/media/video_player_page.dart`

### 14.3 娓呯悊 main.dart `猬渀

- 鍒犻櫎 `import 'package:flash_cloud/flash_cloud.dart'` 涓 CloudDownloadManager 鐨勫紩鐢紙濡傛灉 import 鍙负瀹冿級
- 鍒犻櫎 `CloudDownloadManager().init(...)` 琛?

### 14.4 娓呯悊 flash_im_cache `猬渀

FileCacheManager 鎺ュ彛鍜?FileCacheManagerImpl 鏆傛椂淇濈暀锛堝彲鑳藉叾浠栧湴鏂硅繕鍦ㄧ敤锛夛紝浣?chat_cubit 涓嶅啀浼犲叆銆傚悗缁増鏈彲鑰冭檻鍒犻櫎銆?

---

## 浠诲姟 15锛氱紪璇戦獙璇?`鉁?宸插畬鎴恅

### 15.1 flutter analyze `猬渀

```bash
cd client && flutter analyze
```

瑕佹眰锛氶浂閿欒銆侀浂璀﹀憡銆?

### 15.2 flutter build `猬渀

```bash
cd client && flutter build apk --debug
```

鎴?Windows 妗岄潰锛?

```bash
cd client && flutter build windows
```

瑕佹眰锛氭瀯寤烘垚鍔熴€?

### 15.3 鎵嬪姩楠岃瘉璺緞 `猬渀

- 鑱婂ぉ鍙戝浘 鈫?鐐瑰嚮棰勮 鈫?婊戝姩 + 缂╂斁 + 閫€鍑?
- 鑱婂ぉ鍙戣棰?鈫?鐐瑰嚮鎾斁 鈫?鍏ㄥ睆鎾斁姝ｅ父
- 鑱婂ぉ鍙戣闊?鈫?鎾柊鍋滄棫 鈫?鏆傚仠鎭㈠
- 鑱婂ぉ鍙戞枃浠?鈫?涓嬭浇 鈫?鎵撳紑 / 鍙﹀瓨涓?/ 鎵撳紑鏂囦欢澶?
- 浜戠┖闂存枃浠?鈫?涓嬭浇 鈫?杩涘害鏄剧ず 鈫?瀹屾垚鍚庢墦寮€
