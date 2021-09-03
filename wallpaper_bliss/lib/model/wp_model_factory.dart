import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

abstract class WPModel extends ChangeNotifier {
  WPCategory get currentCategory;
  set currentCategory(WPCategory category);

  Stream<List<WPImageResource>> get stream;
  Future<dynamic> disposeStream();

  void loadWallpapers(WPCategory category);
  void requestNextPage(WPCategory category);

  WPCategory getDefaultCategory();
  WPCategory getParentCategory(WPCategory category);
  Future<void> loadCategories();
  List<WPCategory> getChildrenCategories(WPCategory category);
}

abstract class WPModelFactory {
  WPModel createWPModel();
}

abstract class WPCategory {
  String get id;
  String get title;
  String get thumbUrl;
  String get parent;
  bool get isRoot;
  bool get isParent;
  bool get isDefault;
}

abstract class WPImageResource {
  String get id;
  String get format;
  Timestamp get createdAt;
  String get urlWallp;
  String get urlThumb;
  String get fileName;
  String get category;
  dynamic get likes;
  int get likesNum;
}
