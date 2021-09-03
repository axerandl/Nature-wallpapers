import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';
import 'package:wallpaper_bliss/views/wallpaper_tile.dart';

class WallpapersGrid extends StatefulWidget {
  final WPModel wpModel;
  final AdmobInterstitial interstitialAd;

  WallpapersGrid({
    @required Key key,
    @required this.wpModel,
    @required this.interstitialAd,
  }) : super(key: key);

  @override
  _WallpapersGridState createState() => _WallpapersGridState(wpModel);
}

class _WallpapersGridState extends State<WallpapersGrid>
    with SingleTickerProviderStateMixin {
  final WPModel wpModel;
  AnimationController _animationController;

  _WallpapersGridState(this.wpModel);

  @override
  void initState() {
    wpModel.loadWallpapers(wpModel.currentCategory);
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification.metrics.pixels >=
                scrollNotification.metrics.maxScrollExtent &&
            !scrollNotification.metrics.outOfRange) {
          wpModel.requestNextPage(wpModel.currentCategory);
        }
        return true;
      },
      child: StreamBuilder<List<WPImageResource>>(
          stream: wpModel.stream,
          builder: (BuildContext context,
              AsyncSnapshot<List<WPImageResource>> snapshot) {
            if (snapshot.hasError)
              return new Text('Stream snapshot error: ${snapshot.error}');
            if (snapshot.connectionState != ConnectionState.waiting) {
              List<WPImageResource> resources = snapshot.data;

              _animationController.forward();

              return SlideTransition(
                position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
                    .animate(_animationController),
                child: FadeTransition(
                  opacity: _animationController,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.6,
                        mainAxisSpacing: 6.0,
                        crossAxisSpacing: 6.0,
                      ),
                      itemCount: resources.length,
                      physics: ClampingScrollPhysics(),
                      padding: EdgeInsets.only(top: 4.0),
                      itemBuilder: (BuildContext context, int index) {
                        return GridTile(
                          child: WallpaperTile(
                              imageResource: resources[index],
                              interstitialAd: widget.interstitialAd),
                        );
                      },
                    ),
                  ),
                ),
              );
            } else {
              return SizedBox();
              // Stack(
              //   children: <Widget>[
              //     Positioned.fill(
              //       child: Center(
              //         child: CircularProgressIndicator(
              //           strokeWidth: 2,
              //         ),
              //       ),
              //     )
              //   ],
              // );
            }
          }),
    );
  }
}
