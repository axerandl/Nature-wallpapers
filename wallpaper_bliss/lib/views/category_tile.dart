import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper_bliss/model/firebase/consts.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';

class CategoryTile extends StatelessWidget {
  final WPModel wpModel;
  final WPCategory category;
  final Function(WPCategory, String) callbackCatChanged;

  CategoryTile({
    @required this.wpModel,
    @required this.category,
    @required this.callbackCatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        callbackCatChanged(category, DIRECTIONFORWARD);
      },
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(right: 6),
        child: Stack(children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
                imageUrl: category.thumbUrl,
                height: 60,
                width: 120,
                fit: BoxFit.cover),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.black26,
              alignment: Alignment.center,
              height: 60,
              width: 120,
              child: Text(
                category.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
