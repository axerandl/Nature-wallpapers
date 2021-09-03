import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';

class FirebaseCategoryModel implements WPCategory {
  final String _title;
  final List<String> _children;
  // final List<String> _images;
  final String _parent;
  final String _id;
  final String _thumbUrl;

  const FirebaseCategoryModel(
      {@required String title,
      @required List<String> children,
      // @required List<String> images,
      @required String parent,
      @required String id,
      @required String thumbUrl})
      : _title = title,
        _children = children,
        // _images = images,
        _parent = parent,
        _id = id,
        _thumbUrl = thumbUrl;

  FirebaseCategoryModel.fromSnapshot(DocumentSnapshot doc)
      : assert(doc != null),
        _title = doc.data['title'],
        _id = doc.data['id'],
        _children = doc.data['children']?.cast<String>(),
        // _images = doc.data['images']?.cast<String>(),
        _parent = doc.data['parent'],
        _thumbUrl = doc.data['thumbUrl'];

  FirebaseCategoryModel.fromFirestoreObject(Map<String, dynamic> obj)
      : assert(obj != null),
        _title = obj[obj.keys.toList()[0]]['title'],
        _id = obj[obj.keys.toList()[0]]['id'],
        _children = obj[obj.keys.toList()[0]]['children']?.cast<String>(),
        _parent = obj[obj.keys.toList()[0]]['parent'],
        _thumbUrl = obj[obj.keys.toList()[0]]['thumbUrl'];

  FirebaseCategoryModel._createDefaultCategory()
      : _children = null,
        // _images = null,
        _title = '',
        _id = getDefaultId(),
        _parent = null,
        _thumbUrl = '';

  FirebaseCategoryModel._createRootCategory()
      : _children = null,
        // _images = null,
        _title = '',
        _id = getRootId(),
        _parent = null,
        _thumbUrl = '';

  static FirebaseCategoryModel getDefaultCategory() {
    return _defaultInstance;
  }

  static FirebaseCategoryModel getRootCategory() {
    return _rootInstance;
  }

  static final FirebaseCategoryModel _defaultInstance =
      FirebaseCategoryModel._createDefaultCategory();
  static final FirebaseCategoryModel _rootInstance =
      FirebaseCategoryModel._createRootCategory();

  List<String> get children => _children;
  // List<String> get images => _images;

  @override
  String get parent => _parent;

  @override
  String get id => _id;

  @override
  String get thumbUrl => _thumbUrl;

  @override
  String get title => _title;

  @override
  bool get isRoot => _id == getRootId();

  @override
  bool get isParent => _children != null;

  @override
  bool get isDefault => _id == getDefaultId();

  static String getRootId() => '_root_';
  static String getDefaultId() => 'default';
}
