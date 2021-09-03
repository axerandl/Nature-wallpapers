import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:share/share.dart';
import 'package:wallpaper_bliss/data/channel.dart';
import 'package:wallpaper_bliss/data/consts.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';

class WPViewScreen extends StatelessWidget {
  final WPImageResource imgResource;

  WPViewScreen({@required this.imgResource});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Builder(builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).backgroundColor.withOpacity(0.8),
                  Theme.of(context).backgroundColor.withOpacity(0.9),
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
            ),
            child: Stack(
              children: <Widget>[
                _buildCenterImage(context),
                _buildAppbar(context),
                _buildButtons(context),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCenterImage(BuildContext context) {
    return Hero(
      tag: imgResource.id,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: CachedNetworkImage(
          imageUrl: imgResource.urlWallp,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            constraints: BoxConstraints.expand(),
            child: Stack(
              children: <Widget>[
                Container(color: Colors.black),
                Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Positioned _buildAppbar(BuildContext context) {
    final closeButton = ClipOval(
      child: Container(
        // color: Colors.black.withOpacity(0.1),
        child: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );

    return Positioned(
      child: Container(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  Positioned(left: 8.0, top: 4.0, child: closeButton),
                  Positioned(
                    right: 8.0,
                    top: 4.0,
                    child: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        final RenderBox box = context.findRenderObject();
                        Share.share(imgResource.urlWallp,
                            sharePositionOrigin:
                                box.localToGlobal(Offset.zero) & box.size);
                      },
                      tooltip: "Share",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        height: kToolbarHeight,
        constraints: BoxConstraints.expand(height: kToolbarHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.black,
              Colors.transparent,
            ],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
            stops: const [0.1, 0.9],
          ),
        ),
      ),
      top: 0.0,
      left: 0.0,
      right: 0.0,
    );
  }

  Widget wpButton(BuildContext context, bool lockScreen) {
    return Container(
      padding: EdgeInsets.only(
        bottom: 45.0,
      ),
      child: Center(
        child: FlatButton(
          padding: const EdgeInsets.all(10.0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.grey)),
          onPressed: () {
            _setWallpaper(context, lockScreen);
          },
          child: Text(
            lockScreen ? "Set LockScreen" : "Set Wallpaper",
            textAlign: TextAlign.center,
          ),
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Positioned(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          wpButton(context, false),
        ],
      ),
      left: 0.0,
      right: 0.0,
      bottom: 0.0,
    );
  }

  Future<void> _setWallpaper(BuildContext context, bool lockScreen) async {
    try {
      final targetPlatform = Theme.of(context).platform;

      // get external directory
      Directory externalDir;
      switch (targetPlatform) {
        case TargetPlatform.android:
          externalDir = await getExternalStorageDirectory();
          break;
        case TargetPlatform.iOS:
          externalDir = await getApplicationDocumentsDirectory();
          break;
        default:
          return;
      }
      final filePath =
          path.join(externalDir.path, EXT_DIR, imgResource.fileName);

      if (targetPlatform == TargetPlatform.android) {
        if (await _showDialogSetImageAsWallpaper(
            context, lockScreen ? "lockscreen background" : "wallpaper")) {
          _showProgressDialog(context, "Please wait...");
          try {
            // check image is exists
            if (!File(filePath).existsSync()) {
              await _downloadImage(context);
            }
            var result = await methodChannel.invokeMethod(
              lockScreen ? setLockScreen : setWallpaper,
              <String>[EXT_DIR, imgResource.fileName],
            );
            _showSnackBar(context, result);
          } catch (error) {
            debugPrint('Error: $error');
          } finally {
            Navigator.pop(context);
          }
        }
      } else if (targetPlatform == TargetPlatform.iOS) {
        await methodChannel.invokeMethod(
          setWallpaper,
          <String>[EXT_DIR, imgResource.fileName],
        );
      }
    } on PlatformException catch (e) {
      debugPrint(e.message);
    } catch (e) {
      debugPrint("An error occurred. Set wallpaper: $e");
    }
  }

  void _showSnackBar(BuildContext context, String message,
      [Duration duration = const Duration(milliseconds: 1000)]) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      duration: duration,
      backgroundColor: Colors.black54,
    ));
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final targetPlatform = Theme.of(context).platform;

      if (targetPlatform == TargetPlatform.android) {
        // request runtime permission
        if (!(await Permission.storage.isGranted)) {
          if (!(await Permission.storage.request().isGranted)) {
            return;
          }
        }
      }

      // get external directory
      Directory externalDir;
      switch (targetPlatform) {
        case TargetPlatform.android:
          externalDir = await getExternalStorageDirectory();
          break;
        case TargetPlatform.iOS:
          externalDir = await getApplicationDocumentsDirectory();
          break;
        default:
          return;
      }
      print("externalDir=$externalDir");

      final filePath =
          path.join(externalDir.path, EXT_DIR, imgResource.fileName);

      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      print("Start downloading...");
      final bytes = await http.readBytes(imgResource.urlWallp);
      print("Done downloading...");

      final outBytes = await methodChannel.invokeMethod(
        resizeImage,
        <String, dynamic>{"bytes": bytes},
      );

      //save image to storage
      _saveImage({"filePath": filePath, "bytes": outBytes});

      // call scanFile method, to show image in gallery
      methodChannel
          .invokeMethod(
            scanFile,
            <String>[EXT_DIR, imgResource.fileName],
          )
          .then((result) => print("Scan file: $result"))
          .catchError((e) => print("Scan file error: $e"));
    } on PlatformException catch (e) {
      debugPrint(e.message);
    } catch (e, s) {
      debugPrint("An error occurred. Download image: $e, $s");
    }

    return;
  }

  bool _saveImage(Map<String, dynamic> map) {
    try {
      File(map['filePath'])
        ..createSync(recursive: true)
        ..writeAsBytesSync(map['bytes']);
      return true;
    } catch (e) {
      print('Saved image error: $e');
      return false;
    }
  }

  // Future<bool> _showDialogLockscreenWarning() {
  //   return showDialog<bool>(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text("Important information"),
  //           content: Text(
  //               "Attention. Some manufacturers prohibit setting lockscreen" +
  //                   " backgrounds by third-party applications. In this case, " +
  //                   "choosing this option will not have any effects except " +
  //                   "that it will be not presented to you again."),
  //           actions: <Widget>[
  //             FlatButton(
  //               child: Text("Ok"),
  //               onPressed: () => Navigator.pop(context, true),
  //             ),
  //           ],
  //         );
  //       });
  // }

  Future<bool> _showDialogSetImageAsWallpaper(
      BuildContext context, String str) {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Set $str"),
            content: Text("Set this image as $str?"),
            actions: <Widget>[
              FlatButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              FlatButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Yes"),
              ),
            ],
          );
        });
  }

  void _showProgressDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(message),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
