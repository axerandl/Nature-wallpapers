import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallpaper_bliss/model/firebase/consts.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';

Widget appName() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Text(
        "Nature",
        style: GoogleFonts.pacifico(color: Colors.green),
      ),
      Text(
        " Wallpapers",
        style: GoogleFonts.pacifico(color: Colors.white),
      ),
    ],
  );
}

Widget emptyScreen({Key key}) {
  return Column(
    key: key,
    children: <Widget>[
      SizedBox(
        height: 75,
      ),
      Expanded(
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
      SizedBox(
        height: 50,
      )
    ],
  );
}

Widget categoryBack(
    WPCategory category, Function(WPCategory, String) callbackCatChanged) {
  return IconButton(
    iconSize: 28.0,
    icon: Icon(Icons.navigate_before),
    onPressed: () => callbackCatChanged(category, DIRECTIONBACKWARD),
  );
}
