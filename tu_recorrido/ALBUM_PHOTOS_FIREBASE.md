# Sistema de Fotos de Experiencia en Firebase

## 📁 Estructura de Archivos Creados

### Modelos
- `lib/models/album_photo.dart` - Modelo de datos para fotos del álbum

### Servicios  
- `lib/services/album_photos_service.dart` - Servicio completo para gestión de fotos en Firebase

### Widgets de Ejemplo
- `lib/widgets/album_photos_example.dart` - Widget ejemplo mostrando cómo usar el servicio

### Reglas de Seguridad
- `firestore.rules` - Reglas actualizadas para proteger fotos del álbum en Firestore
- `storage.rules` - Nuevas reglas para proteger imágenes en Firebase Storage

## 🏗️ Arquitectura

### Firebase Firestore
```
users/{userId}/album_photos/{photoId}
{
  id: string,
  badgeId: string,              // ID de la insignia asociada
  imageUrl: string,             // URL de Firebase Storage
  thumbnailUrl?: string,        // URL de miniatura (futuro)
  description?: string,         // Descripción del usuario
  uploadDate: timestamp,        // Fecha de subida
  location?: string,           // "lat,lng" opcional
  metadata?: object            // Datos adicionales
}
```

### Firebase Storage
```
album_photos/{userId}/{photoId}.jpg
```

## 🛡️ Seguridad

### Reglas de Firestore
- Solo el propietario puede leer/escribir sus fotos
- Validación de esquema obligatoria
- Los administradores NO tienen acceso a fotos personales

### Reglas de Storage
- Solo el propietario puede subir/leer/eliminar sus imágenes
- Validación de tipo de archivo (solo imágenes)
- Límite de tamaño: 10MB por foto

## 🚀 Funcionalidades del Servicio

### `AlbumPhotosService`
- ✅ `uploadPhoto()` - Subir foto con metadatos
- ✅ `getUserPhotos()` - Obtener todas las fotos del usuario
- ✅ `getPhotosForBadge()` - Fotos de una insignia específica
- ✅ `watchUserPhotos()` - Stream en tiempo real
- ✅ `updatePhotoDescription()` - Actualizar descripción
- ✅ `deletePhoto()` - Eliminar foto y archivo
- ✅ `getUserAlbumStats()` - Estadísticas del álbum
- ✅ `hasReachedPhotoLimit()` - Verificar límite de fotos

## 📱 Integración con Álbum Existente

### 1. Reemplazar `_addPhotoFor()` en `album.dart`
```dart
Future<void> _addPhotoFor(String parentId) async {
  try {
    // Verificar límite
    final hasReachedLimit = await AlbumPhotosService.hasReachedPhotoLimit();
    if (hasReachedLimit) {
      // Mostrar mensaje de límite
      return;
    }

    // Seleccionar imagen
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 85
    );
    if (file == null) return;

    // Subir a Firebase
    await AlbumPhotosService.uploadPhoto(
      imageFile: file,
      badgeId: parentId,
    );

    // Mostrar mensaje de éxito
  } catch (e) {
    // Manejar error
  }
}
```

### 2. Usar Stream para cargar fotos
```dart
@override
void initState() {
  super.initState();
  
  // Escuchar cambios en fotos del usuario
  AlbumPhotosService.watchUserPhotos().listen((photos) {
    setState(() {
      // Actualizar UI con fotos de Firebase
    });
  });
}
```

### 3. Integrar eliminación con confirmación
```dart
Future<void> _deletePhoto(AlbumPhoto photo) async {
  final confirmed = await showDialog<bool>(/*...*/);
  if (confirmed == true) {
    await AlbumPhotosService.deletePhoto(photo.id);
    // Foto eliminada automáticamente del Storage y Firestore
  }
}
```

## 🔄 Ventajas sobre SharedPreferences

| Aspecto | SharedPreferences | Firebase |
|---------|------------------|----------|
| **Persistencia** | ❌ Se pierde al limpiar app | ✅ Permanente |
| **Sincronización** | ❌ Solo local | ✅ Múltiples dispositivos |
| **Límite de tamaño** | ❌ Muy limitado | ✅ Prácticamente ilimitado |
| **Respaldo** | ❌ No hay respaldo | ✅ Respaldo automático |
| **Performance** | ❌ Base64 es lento | ✅ URLs optimizadas |
| **Offline** | ✅ Siempre disponible | ✅ Cache automático |
| **Gestión** | ❌ Manual compleja | ✅ Automática |

## 📝 Próximos Pasos

1. **Migrar datos existentes** (opcional):
   ```dart
   // Convertir fotos de SharedPreferences a Firebase
   // Puedes crear un script de migración si es necesario
   ```

2. **Integrar en el modal de imagen actual**:
   - Reemplazar el botón de eliminar actual
   - Usar AlbumPhotosService en lugar de SharedPreferences

3. **Optimizaciones futuras**:
   - Generar thumbnails automáticamente
   - Compresión inteligente de imágenes
   - Carga lazy con paginación
   - Búsqueda por texto en descripciones

## 🧪 Prueba la Implementación

1. Copia el código del widget ejemplo
2. Intégralo en una pantalla de prueba
3. Verifica que las fotos se suban correctamente
4. Confirma que las reglas de seguridad funcionan
5. Prueba la eliminación y actualización de descripciones

La implementación está completa y lista para usar. ¡Las fotos ahora estarán seguras en Firebase! 🎉