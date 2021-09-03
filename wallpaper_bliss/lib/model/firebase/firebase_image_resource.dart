import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:wallpaper_bliss/model/wp_model_factory.dart';

class FirebaseImageResource implements WPImageResource {
  final String _id;
  final String _category;
  final String _imageName;
  final String _imageUrl;
  final String _thumbUrl;
  final Timestamp _timestamp;
  final dynamic _likes;
  final int _likesNum;

  const FirebaseImageResource(
      {@required String id,
      @required String category,
      @required String imageName,
      @required String imageUrl,
      @required String thumbUrl,
      @required Timestamp timestamp,
      @required dynamic likes,
      @required int likesNum})
      : _id = id,
        _category = category,
        _imageName = imageName,
        _imageUrl = imageUrl,
        _thumbUrl = thumbUrl,
        _timestamp = timestamp,
        _likes = likes,
        _likesNum = likesNum;

  FirebaseImageResource.fromSnapshot(DocumentSnapshot doc)
      : assert(doc != null),
        _id = doc.data['id'],
        _category = doc.data['category'],
        _imageName = doc.data['imageName'],
        _imageUrl = doc.data['imageUrl'],
        _thumbUrl = doc.data['thumbUrl'],
        _likes = doc.data['likes'],
        _timestamp = doc.data['timestamp'],
        _likesNum = doc.data['likesNum'];

  @override
  String get category => _category;

  @override
  String get id => _id;

  @override
  String get format => _imageName.substring(_imageName.indexOf('.') + 1);

  @override
  Timestamp get createdAt => _timestamp;

  @override
  String get fileName => _imageName;

  @override
  dynamic get likes => _likes;

  @override
  int get likesNum => _likesNum;

  @override
  String get urlThumb => _thumbUrl;

  @override
  String get urlWallp => _imageUrl;
}
