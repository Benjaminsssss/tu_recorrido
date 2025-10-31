# tu_recorrido

Proyecto Flutter "Tu Recorrido".

Nota rápida sobre imágenes:
- El contenido provisional en `assets/data/places.json` fue eliminado. Las imágenes deben provenir ahora de Firestore (`places` collection, campo `imageUrl`) o desde Firebase Storage (usar `StorageService` para uploads y guardar la URL en Firestore).

Si necesitas que implemente la subida directa desde la app (Storage + guardado de URL en Firestore), dime y la agrego.
