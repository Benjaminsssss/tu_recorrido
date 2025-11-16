import 'package:flutter/foundation.dart';

/// Notificador global para cambios en lugares guardados
class SavedPlacesNotifier extends ChangeNotifier {
  static final SavedPlacesNotifier _instance = SavedPlacesNotifier._internal();

  factory SavedPlacesNotifier() {
    return _instance;
  }

  SavedPlacesNotifier._internal();

  // Notificar que un lugar fue guardado o eliminado
  void notifyPlaceChanged(String placeId, bool isSaved) {
    notifyListeners();
  }

  // Notificar cambios generales
  void notifyChanges() {
    notifyListeners();
  }
}