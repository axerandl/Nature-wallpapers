import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wallpaper_bliss/model/firebase/consts.dart';
import 'package:wallpaper_bliss/model/firebase/firebase_category_model.dart';
import 'package:wallpaper_bliss/model/firebase/firebase_image_resource.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';

class FirebaseWPModelFactory implements WPModelFactory {
  @override
  WPModel createWPModel() {
    return FirebaseWPModel();
  }
}

class FirebaseWPModel extends ChangeNotifier implements WPModel {
  static const IMAGES_PER_PAGE = 7;

  StreamController<List<WPImageResource>> _streamController =
      StreamController<List<WPImageResource>>.broadcast();

  List<FirebaseImageResource> _images = [];
  Map<String, DocumentSnapshot> _imagesSnapshotsMap = {};
  List<WPCategory> _categoriesCache = [];
  WPCategory _currentCategory = FirebaseCategoryModel.getDefaultCategory();

  @override
  WPCategory get currentCategory => _currentCategory;

  @override
  set currentCategory(WPCategory category) {
    _currentCategory = category;
    notifyListeners();
  }

  int _curPage;
  bool _isRequestingNextPage = false;

  Stream<List<WPImageResource>> get stream => _streamController.stream;
  Future<dynamic> disposeStream() => _streamController.close();

  @override
  WPCategory getParentCategory(WPCategory category) {
    assert(_categoriesCache.isNotEmpty);

    if (!category.isDefault || !category.isRoot) {
      for (var parent in _categoriesCache) {
        if (parent.id == category.parent) {
          return parent;
        }
      }
    }
    return getDefaultCategory();
  }

  /// Get categories which have this category's id as their parent
  @override
  Future<void> loadCategories() async {
    assert(_categoriesCache.isEmpty);

    return await _populateCategoriesCache();
  }

  @override
  List<WPCategory> getChildrenCategories(WPCategory category) {
    assert(_categoriesCache.isNotEmpty);

    List<WPCategory> categories = [];

    if (category.isDefault) {
      for (var child in _categoriesCache) {
        if (child.parent == FirebaseCategoryModel.getRootId()) {
          categories.add(child);
        }
      }
    } else {
      for (var child in _categoriesCache) {
        if (child.parent == category.id) {
          categories.add(child);
        }
      }
    }

    return categories;
  }

  Future<List<WPCategory>> _fetchAllCategories() async {
    List<WPCategory> categories = [];

    CollectionReference colRef =
        Firestore.instance.collection(CATEGORIES_COLLECTION);

    DocumentSnapshot doc = await colRef.document('all_categories').get();

    for (Map object in doc.data['categories']) {
      categories.add(FirebaseCategoryModel.fromFirestoreObject(object));
    }

    return Future<List<WPCategory>>.value(categories);
  }

  Future<void> _populateCategoriesCache() async {
    assert(_categoriesCache.isEmpty);

    _categoriesCache.addAll(await _fetchAllCategories());
  }

  void loadWallpapers(WPCategory category) async {
    assert(category.runtimeType == FirebaseCategoryModel);
    _images = [];
    _imagesSnapshotsMap = {};
    _curPage = 0;

    var count = 0;
    var result = await _getImages(category);
    _images.addAll(result);
    count += result.length;

    debugPrint('Adding $count images to stream');
    _streamController.sink.add(_images);
  }

  void requestNextPage(WPCategory category) async {
    if (!_isRequestingNextPage) {
      _isRequestingNextPage = true;
      _curPage++;
      debugPrint('Requesting $_curPage page');

      var imagesLen = _images?.length ?? 0;
      var count = 0;
      var result = await _getImages(category);
      if (result.length > 0) {
        _images.addAll(result);
        count += result.length;
      }

      if (imagesLen == _images?.length ?? 0) {
        _curPage--;
        debugPrint('Nothing new to add...');
      } else {
        debugPrint('Adding $count images to stream');
        _streamController.sink.add(_images);
      }

      _isRequestingNextPage = false;
    }
  }

  ///fetch images for specific category
  Future<List<FirebaseImageResource>> _getImages(
      FirebaseCategoryModel category) async {
    List<FirebaseImageResource> imagesList = [];
    Query query = Firestore.instance.collection(WALLPAPERS_COLLECTION);

    if (category.isDefault) {
      query =
          query.limit(IMAGES_PER_PAGE).orderBy('likesNum', descending: true);
    } else {
      query = query
          .limit(IMAGES_PER_PAGE)
          .orderBy('likesNum', descending: true)
          .where('ancestors', arrayContains: category.id);
    }

    if (_imagesSnapshotsMap.containsKey(category.id)) {
      query = query.startAfterDocument(_imagesSnapshotsMap[category.id]);
    }

    QuerySnapshot querySnapshot = await query.getDocuments();
    List<DocumentSnapshot> docs = querySnapshot.documents;

    if (docs.isNotEmpty) {
      _imagesSnapshotsMap[category.id] = docs.last;
    }

    docs.forEach(
        (doc) => imagesList.add(FirebaseImageResource.fromSnapshot(doc)));

    return Future<List<FirebaseImageResource>>.value(imagesList);
  }

  @override
  WPCategory getDefaultCategory() {
    return FirebaseCategoryModel.getDefaultCategory();
  }
}
