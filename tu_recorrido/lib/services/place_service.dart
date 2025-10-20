import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/place.dart';

class PlaceService {
  /// Carga los lugares desde el archivo JSON local en assets/data/places.json
  static Future<List<Place>> loadPlacesFromJson() async {
    final jsonStr = await rootBundle.loadString('assets/data/places.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.map((e) => Place.fromJson(e)).toList();
  }
}
