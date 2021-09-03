import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';
import 'package:wallpaper_bliss/views/categories_list.dart';
import 'package:wallpaper_bliss/views/wallpapers_grid.dart';
import 'package:wallpaper_bliss/data/utils.dart';

import 'package:wallpaper_bliss/views/widget.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  AdmobBanner admobBanner;
  AdmobInterstitial admobInterstitial;

  _CategoryScreenState();

  @override
  void initState() {
    AdMobUtil admobUtil = Provider.of<AdMobUtil>(context, listen: false);
    admobBanner = admobUtil.admobBanner;
    admobInterstitial = admobUtil.interstitialAd;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: appName(),
        elevation: 1.0,
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder(
          future: Provider.of<WPModel>(context, listen: false).loadCategories(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? emptyScreen(
                      key: ValueKey(0),
                    )
                  : Column(
                      key: ValueKey(1),
                      children: <Widget>[
                        CategoriesList(),
                        Expanded(
                          child: Consumer<WPModel>(
                            builder: (BuildContext context, WPModel wpModel,
                                Widget child) {
                              return WallpapersGrid(
                                key: Key(wpModel.currentCategory.id),
                                interstitialAd: admobInterstitial,
                                wpModel: wpModel,
                              );
                            },
                          ),
                        ),
                        admobBanner
                      ],
                    ),
            );
          }),
    );
  }
}
