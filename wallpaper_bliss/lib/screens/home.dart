import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:wallpaper_bliss/data/consts.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';
import 'package:wallpaper_bliss/screens/category_screen.dart';
import 'package:launch_review/launch_review.dart';
import 'package:wallpaper_bliss/data/utils.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    RateMyApp rateMyApp = RateMyApp(
        minLaunches: 3,
        remindDays: 1,
        minDays: 0,
        googlePlayIdentifier: GOOGLE_PLAY_ID);

    rateMyApp.init().then((_) {
      if (rateMyApp.shouldOpenDialog) {
        debugPrint('Showing rating dialog');
        rateMyApp.showStarRateDialog(
          context,
          title: 'Rate this app',
          message:
              'If you like this app, please take a little bit of your time to leave a rating. Thank you!',
          actionsBuilder: (context, stars) {
            return [
              FlatButton(
                child: Text('OK'),
                onPressed: () async {
                  print('Thanks for the ' +
                      (stars == null ? '0' : stars.round().toString()) +
                      ' star(s) !');
                  await rateMyApp
                      .callEvent(RateMyAppEventType.rateButtonPressed);
                  Navigator.pop<RateMyAppDialogButton>(
                      context, RateMyAppDialogButton.rate);
                  LaunchReview.launch(androidAppId: GOOGLE_PLAY_ID);
                },
              ),
            ];
          },
          dialogStyle: DialogStyle(
            titleAlign: TextAlign.center,
            messageAlign: TextAlign.center,
            messagePadding: EdgeInsets.only(bottom: 20),
          ),
          starRatingOptions: StarRatingOptions(),
          onDismissed: () =>
              rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed),
        );
      } else {
        debugPrint('Not showing rating dialog');
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    Provider.of<AdMobUtil>(context, listen: false).interstitialAd.dispose();
    Provider.of<WPModel>(context, listen: false).disposeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CategoryScreen();
  }
}
