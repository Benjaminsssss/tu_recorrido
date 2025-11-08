# Estructura Social - Firestore

Este documento describe la estructura de datos de Firestore para las funcionalidades sociales de la aplicación.

## 📊 Colecciones y Estructura

### 1. **users** (Actualizada)
Colección principal de usuarios con campos adicionales para funcionalidades sociales.

```
users/{userId}
  ├── uid: string
  ├── email: string
  ├── displayName: string?
  ├── photoURL: string?
  ├── backgroundURL: string?
  ├── nombre: string?
  ├── apodo: string?
  ├── fechaNacimiento: string?
  ├── region: string?
  ├── comuna: string?
  ├── activo: boolean
  ├── role: string?
  ├── createdAt: timestamp
  ├── updatedAt: timestamp
  │
  ├── --- NUEVOS CAMPOS SOCIALES ---
  ├── followersCount: number (default: 0)
  ├── followingCount: number (default: 0)
  ├── badgesCount: number (default: 0)
  ├── placesVisitedCount: number (default: 0)
  ├── isPublic: boolean (default: true)
  ├── showBadges: boolean (default: true)
  └── showAlbum: boolean (default: true)
```

**Campos de Privacidad:**
- `isPublic`: Si es `true`, cualquiera puede ver el perfil. Si es `false`, solo seguidores.
- `showBadges`: Controla si las insignias son visibles públicamente.
- `showAlbum`: Controla si el álbum de fotos es visible públicamente.

---

### 2. **followers** (Nueva)
Almacena los seguidores de cada usuario.

```
followers/{userId}/followers/{followerId}
  ├── displayName: string
  ├── photoURL: string?
  └── timestamp: timestamp
```

**Ejemplo:**
```
followers/user123/followers/user456
  ├── displayName: "Juan Pérez"
  ├── photoURL: "https://..."
  └── timestamp: 2025-11-06T10:30:00Z
```

**Nota:** `user456` sigue a `user123`.

---

### 3. **following** (Nueva)
Almacena los usuarios que cada usuario sigue.

```
following/{userId}/following/{followingId}
  ├── displayName: string
  ├── photoURL: string?
  └── timestamp: timestamp
```

**Ejemplo:**
```
following/user123/following/user789
  ├── displayName: "María López"
  ├── photoURL: "https://..."
  └── timestamp: 2025-11-06T11:00:00Z
```

**Nota:** `user123` sigue a `user789`.

---

### 4. **feed** (Nueva)
Feed personalizado de actividad de usuarios seguidos.

```
feed/{userId}/items/{itemId}
  ├── type: string ("badgeObtained" | "placeVisited")
  ├── userId: string
  ├── userName: string
  ├── userPhotoURL: string?
  ├── timestamp: timestamp
  │
  ├── --- Si type = "badgeObtained" ---
  ├── badgeId: string?
  ├── badgeName: string?
  ├── badgeImageUrl: string?
  │
  └── --- Si type = "placeVisited" ---
      ├── placeId: string?
      ├── placeName: string?
      ├── placeImageUrl: string?
      ├── placeLatitude: number?
      └── placeLongitude: number?
```

**Ejemplo - Insignia obtenida:**
```
feed/user123/items/item001
  ├── type: "badgeObtained"
  ├── userId: "user456"
  ├── userName: "Juan Pérez"
  ├── userPhotoURL: "https://..."
  ├── timestamp: 2025-11-06T14:30:00Z
  ├── badgeId: "badge001"
  ├── badgeName: "Explorador"
  └── badgeImageUrl: "https://..."
```

**Ejemplo - Lugar visitado:**
```
feed/user123/items/item002
  ├── type: "placeVisited"
  ├── userId: "user789"
  ├── userName: "María López"
  ├── userPhotoURL: "https://..."
  ├── timestamp: 2025-11-06T15:45:00Z
  ├── placeId: "place001"
  ├── placeName: "Museo Nacional"
  ├── placeImageUrl: "https://..."
  ├── placeLatitude: -33.4489
  └── placeLongitude: -70.6693
```

---

## 🔒 Reglas de Seguridad

### Lectura de Perfiles
- **Público (`isPublic: true`)**: Cualquiera autenticado puede ver
- **Privado (`isPublic: false`)**: Solo el dueño, seguidores, y admins

### Insignias del Usuario
- **Visible si**: `showBadges: true` Y (`isPublic: true` O el usuario sigue al dueño)
- **Siempre visible para**: Dueño y admins

### Álbum de Fotos
- **Visible si**: `showAlbum: true` Y (`isPublic: true` O el usuario sigue al dueño)
- **Siempre visible para**: Dueño y admins

### Followers/Following
- **Lectura**: Visible si el perfil es público o si sigues al usuario
- **Escritura**: Solo el usuario puede agregar/eliminar sus propias relaciones

### Feed
- **Lectura**: Solo el dueño del feed
- **Escritura**: Sistema (a través de la app al realizar acciones)

---

## 🔄 Flujo de Seguimiento

### Cuando User A sigue a User B:

1. **Crear documento en `following`:**
   ```
   following/userA/following/userB
   ```

2. **Crear documento en `followers`:**
   ```
   followers/userB/followers/userA
   ```

3. **Incrementar contadores:**
   - `users/userA.followingCount++`
   - `users/userB.followersCount++`

### Cuando User A deja de seguir a User B:

1. **Eliminar documento de `following`:**
   ```
   DELETE following/userA/following/userB
   ```

2. **Eliminar documento de `followers`:**
   ```
   DELETE followers/userB/followers/userA
   ```

3. **Decrementar contadores:**
   - `users/userA.followingCount--`
   - `users/userB.followersCount--`

---

## 📈 Actualización de Contadores

Los contadores deben actualizarse automáticamente cuando:

### `badgesCount`:
- Se incrementa cuando se agrega una insignia en `users/{uid}/insignias/{badgeId}`

### `placesVisitedCount`:
- Se incrementa cuando se agrega una estación en `users/{uid}/estaciones_visitadas/{stationId}`

### `followersCount` y `followingCount`:
- Se actualizan al seguir/dejar de seguir

---

## 🎯 Generación del Feed

Cuando un usuario realiza una acción (obtiene insignia, visita lugar), se debe:

1. Obtener lista de seguidores desde `followers/{userId}/followers/*`
2. Para cada seguidor, crear un documento en su feed:
   ```
   feed/{followerId}/items/{itemId}
   ```
3. El feed se ordena por `timestamp` descendente
4. Se puede implementar paginación para feeds largos

---

## 💡 Consideraciones de Rendimiento

1. **Denormalización**: Guardamos `displayName` y `photoURL` en followers/following para evitar lecturas adicionales
2. **Contadores**: Se mantienen en el documento de usuario para acceso rápido
3. **Feed**: Se pre-genera para cada seguidor (fan-out on write)
4. **Índices**: Crear índices compuestos en Firestore para queries eficientes:
   - `feed/{userId}/items`: ordenado por `timestamp DESC`
   - `followers/{userId}/followers`: ordenado por `timestamp DESC`
   - `following/{userId}/following`: ordenado por `timestamp DESC`

---

## 🔍 Queries Comunes

### Obtener seguidores de un usuario
```dart
FirebaseFirestore.instance
  .collection('followers')
  .doc(userId)
  .collection('followers')
  .orderBy('timestamp', descending: true)
  .limit(20)
  .get()
```

### Obtener usuarios seguidos
```dart
FirebaseFirestore.instance
  .collection('following')
  .doc(userId)
  .collection('following')
  .orderBy('timestamp', descending: true)
  .limit(20)
  .get()
```

### Obtener feed social
```dart
FirebaseFirestore.instance
  .collection('feed')
  .doc(userId)
  .collection('items')
  .orderBy('timestamp', descending: true)
  .limit(20)
  .get()
```

### Verificar si sigo a un usuario
```dart
FirebaseFirestore.instance
  .collection('following')
  .doc(myUserId)
  .collection('following')
  .doc(targetUserId)
  .get()
  .then((doc) => doc.exists)
```
