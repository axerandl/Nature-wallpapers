import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_bliss/model/firebase/consts.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';
import 'package:wallpaper_bliss/views/category_tile.dart';
import 'package:wallpaper_bliss/views/widget.dart';

class CategoriesList extends StatefulWidget {
  const CategoriesList();

  @override
  _CategoriesListState createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList>
    with SingleTickerProviderStateMixin {
  WPModel wpModel;
  WPCategory wpCategory;
  List<WPCategory> categories;
  Offset beginOffset = Offset(0, 0);
  Tween<Offset> tween = Tween(begin: Offset.zero, end: Offset.zero);
  AnimationController _animationController;

  @override
  void initState() {
    wpModel = Provider.of<WPModel>(context, listen: false);
    wpCategory = wpModel.currentCategory;
    categories = wpModel.getChildrenCategories(wpCategory);

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));

    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void catChanged(WPCategory category, String direction) {
    setState(() {
      wpCategory = category;
      wpModel.currentCategory = category;
      categories = wpModel.getChildrenCategories(wpCategory);

      beginOffset =
          direction == DIRECTIONFORWARD ? Offset(1, 0) : Offset(-1, 0);
      tween = Tween(begin: beginOffset, end: Offset.zero);
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: tween.animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      )),
      child: Row(
        key: Key(wpCategory.id),
        children: <Widget>[
          !wpCategory.isDefault && !wpCategory.isRoot
              ? Container(
                  height: 75,
                  alignment: Alignment.center,
                  child: categoryBack(
                      wpModel.getParentCategory(wpCategory), catChanged),
                )
              : SizedBox(),
          Expanded(
            child: Container(
              height: 75,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  if (categories[index].id != wpCategory.id) {
                    return CategoryTile(
                      wpModel: wpModel,
                      category: categories[index],
                      callbackCatChanged: catChanged,
                    );
                  } else {
                    return SizedBox(
                      height: 75.0,
                    );
                  }
                },
              ),
            ),
          ),
        ],
        // ),
      ),
      // ),
    );
  }
}
