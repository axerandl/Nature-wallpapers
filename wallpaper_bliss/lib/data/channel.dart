import 'package:flutter/services.dart';

const String channel = 'wallpaper_bliss';
const methodChannel = MethodChannel(channel);

/// Set image as wallpaper
/// Arguments: [List] of [String]s, is path of image file, start from folder in external storage directory
/// Return   : a [String] when success or [PlatformException] when failed
/// Example:
/// path of image: 'external storage directory'/EXT_DIR/image.png
///   methodChannel.invokeMethod(
///      setWallpaper,
///      <String>[EXT_DIR, 'image.png'],
///   );
const String setWallpaper = 'setWallpaper';

/// Set image as a lockscreen background
/// Arguments: [List] of [String]s, is path of image file, start from folder in external storage directory
/// Return   : a [String] when success or [null] when failed
/// Example:
/// path of image: 'external storage directory'/EXT_DIR/image.png
///   methodChannel.invokeMethod(
///      setLockScreen,
///      <String>[EXT_DIR, 'image.png'],
///   );
const String setLockScreen = 'setLockScreen';

/// Scan image file, after scan, we can see image in gallery
/// Arguments: [List] of [String]s, is path of image file, start from folder in external storage directory
/// Return   : a [String] when success or [PlatformException] when failed
/// Example:
/// path of image: 'external storage directory'/EXT_DIR/image.png
///   methodChannel.invokeMethod(scanFile, <String>[
///     EXT_DIR,
///     'image.png'
///   ]);
const String scanFile = 'scanFile';

/// Resize image
/// Arguments: [Map], keys is [String]s, values is dynamic type
/// Return   : a [Uint8List] when success or [PlatformException] when failed
/// Example:
/// final Uint8List outBytes = await methodChannel.invokeMethod(
///   resizeImage,
///   <String, dynamic>{
///     'bytes': bytes
///   },
/// );
const String resizeImage = 'resizeImage';
