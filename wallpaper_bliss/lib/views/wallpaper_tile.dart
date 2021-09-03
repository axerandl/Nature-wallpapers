import 'package:admob_flutter/admob_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:wallpaper_bliss/data/utils.dart';
import 'package:wallpaper_bliss/model/firebase/consts.dart';
import 'package:wallpaper_bliss/screens/wp_view_screen.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';

class WallpaperTile extends StatefulWidget {
  final WPImageResource imageResource;
  final AdmobInterstitial interstitialAd;

  WallpaperTile({
    @required this.imageResource,
    @required this.interstitialAd,
  });

  @override
  _WallpaperTileState createState() => _WallpaperTileState();
}

class _WallpaperTileState extends State<WallpaperTile> {
  String uuid;
  int likesNum;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    AndroidInfo info = Provider.of<AndroidInfo>(context, listen: false);
    uuid = info.uuid;
    likesNum = widget.imageResource.likesNum;
    isLiked = widget.imageResource.likes[uuid] == true;
  }

  Future<void> _likeImage(userId) async {
    final image = Firestore.instance
        .collection(WALLPAPERS_COLLECTION)
        .document(widget.imageResource.id);
    isLiked = widget.imageResource.likes[userId] == true;
    var newLikesNum;
    if (isLiked) {
      newLikesNum = likesNum - 1;
      Firestore.instance.runTransaction((Transaction transaction) {
        return transaction.update(image, {
          'likes.$userId': false,
          'likesNum': newLikesNum,
        });
      });
      setState(() {
        isLiked = false;
        widget.imageResource.likes[userId] = false;
        likesNum = newLikesNum;
      });
    } else {
      newLikesNum = likesNum + 1;
      Firestore.instance.runTransaction((Transaction transaction) {
        return transaction.update(image, {
          'likes.$userId': true,
          'likesNum': newLikesNum,
        });
      });
      setState(() {
        isLiked = true;
        widget.imageResource.likes[userId] = true;
        likesNum = newLikesNum;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          onTap: () async {
            if (context.read<AdShowAid>().ready()) {
              if (await widget.interstitialAd.isLoaded) {
                widget.interstitialAd.show();
              } else {
                debugPrint("Interstitial ad not loaded");
              }
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        WPViewScreen(imgResource: widget.imageResource)));
          },
          child: Hero(
            tag: widget.imageResource.id,
            child: Container(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                      imageUrl: widget.imageResource.urlThumb,
                      placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                            strokeWidth: 2,
                          )),
                      errorWidget: (context, url, error) =>
                          Center(child: const Icon(Icons.error)),
                      fit: BoxFit.cover)),
            ),
          ),
        ),
        Positioned(
          bottom: 10.0,
          left: 10.0,
          child: GestureDetector(
              onTap: () async {
                _likeImage(uuid);
              },
              child: Container(
                width: 50.0,
                height: 50.0,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.44)),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey<int>(likesNum),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      isLiked
                          ? Icon(
                              Icons.thumb_up,
                              size: 28.0,
                              color: Theme.of(context).accentColor,
                            )
                          : Icon(
                              OMIcons.thumbUp,
                              size: 28.0,
                              color: Theme.of(context).accentColor,
                            ),
                      Text(
                        '$likesNum',
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ),
      ],
    );
  }
}
