# Guía de Integración - Servicios Sociales

Esta guía explica cómo integrar los nuevos servicios sociales en tu código existente.

## 📦 Servicios Creados

### 1. **FollowService** - Gestión de seguidores
### 2. **UserProfileService** - Perfiles públicos
### 3. **SocialFeedService** - Feed de actividad

---

## 🔌 Integración en el Código Existente

### 1️⃣ Cuando un usuario OBTIENE UNA INSIGNIA

Busca en tu código donde agregas una insignia al usuario (probablemente en un servicio o cuando escanea un QR).

**ANTES:**
```dart
// Solo agregabas la insignia
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('insignias')
  .doc(badgeId)
  .set({
    'fechaObtenida': FieldValue.serverTimestamp(),
  });
```

**DESPUÉS:**
```dart
import 'package:tu_recorrido/services/social_services.dart';

// 1. Agregar la insignia (como antes)
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('insignias')
  .doc(badgeId)
  .set({
    'fechaObtenida': FieldValue.serverTimestamp(),
  });

// 2. Actualizar contador de insignias
final profileService = UserProfileService();
await profileService.updateUserStats(
  userId: userId,
  badgesCountDelta: 1,
);

// 3. Crear item en el feed de seguidores
final feedService = SocialFeedService();
await feedService.createBadgeFeedItem(
  badgeId: badgeId,
  badgeName: badgeName,  // Obtener de la insignia
  badgeImageUrl: badgeImageUrl,  // Obtener de la insignia
);
```

---

### 2️⃣ Cuando un usuario VISITA UN LUGAR

Busca donde guardas una estación visitada.

**ANTES:**
```dart
// Solo guardabas la visita
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('estaciones_visitadas')
  .doc(estacionId)
  .set({
    'estacionId': estacionId,
    'estacionNombre': estacionNombre,
    'fechaVisita': FieldValue.serverTimestamp(),
    // ... otros campos
  });
```

**DESPUÉS:**
```dart
import 'package:tu_recorrido/services/social_services.dart';

// 1. Guardar la visita (como antes)
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('estaciones_visitadas')
  .doc(estacionId)
  .set({
    'estacionId': estacionId,
    'estacionNombre': estacionNombre,
    'fechaVisita': FieldValue.serverTimestamp(),
    // ... otros campos
  });

// 2. Actualizar contador de lugares visitados
final profileService = UserProfileService();
await profileService.updateUserStats(
  userId: userId,
  placesVisitedCountDelta: 1,
);

// 3. Crear item en el feed de seguidores
final feedService = SocialFeedService();
await feedService.createPlaceVisitedFeedItem(
  placeId: estacionId,
  placeName: estacionNombre,
  placeImageUrl: estacionImageUrl,  // Si tienes imagen
  placeLatitude: latitud,
  placeLongitude: longitud,
);
```

---

### 3️⃣ Actualizar documento de USUARIO al registrarse

Cuando creas un nuevo usuario, agrega los campos sociales.

**Busca donde se crea el usuario en Firestore** (probablemente en un AuthService):

**ANTES:**
```dart
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .set({
    'uid': userId,
    'email': email,
    'displayName': displayName,
    'activo': true,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

**DESPUÉS:**
```dart
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .set({
    'uid': userId,
    'email': email,
    'displayName': displayName,
    'activo': true,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    
    // NUEVOS CAMPOS SOCIALES
    'followersCount': 0,
    'followingCount': 0,
    'badgesCount': 0,
    'placesVisitedCount': 0,
    'isPublic': true,
    'showBadges': true,
    'showAlbum': true,
  });
```

---

## 🎨 Uso en la UI

### Mostrar botón "Seguir" en el perfil de otro usuario

```dart
import 'package:tu_recorrido/services/social_services.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;  // ID del usuario cuyo perfil estamos viendo
  
  const UserProfileScreen({required this.userId});
  
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _followService = FollowService();
  final _profileService = UserProfileService();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _followService.followStatusStream(widget.userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        
        return ElevatedButton(
          onPressed: () async {
            if (isFollowing) {
              await _followService.unfollowUser(widget.userId);
            } else {
              await _followService.followUser(widget.userId);
            }
          },
          child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
        );
      },
    );
  }
}
```

---

### Mostrar estadísticas del usuario

```dart
StreamBuilder<UserProfile?>(
  stream: _profileService.getUserProfileStream(userId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final profile = snapshot.data!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat('Insignias', profile.badgesCount),
        _buildStat('Lugares', profile.placesVisitedCount),
        _buildStat('Seguidores', profile.followersCount),
        _buildStat('Siguiendo', profile.followingCount),
      ],
    );
  },
);

Widget _buildStat(String label, int value) {
  return Column(
    children: [
      Text(
        '$value',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      Text(label, style: TextStyle(color: Colors.grey)),
    ],
  );
}
```

---

### Mostrar feed social en el tab "Siguiendo"

```dart
import 'package:tu_recorrido/services/social_services.dart';
import 'package:tu_recorrido/models/social_models.dart';

class FollowingTab extends StatelessWidget {
  final _feedService = SocialFeedService();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedItem>>(
      stream: _feedService.getFeedStream(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Sigue a usuarios para ver su actividad'),
          );
        }
        
        final feedItems = snapshot.data!;
        
        return ListView.builder(
          itemCount: feedItems.length,
          itemBuilder: (context, index) {
            final item = feedItems[index];
            return _buildFeedItem(item);
          },
        );
      },
    );
  }
  
  Widget _buildFeedItem(FeedItem item) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: item.userPhotoURL != null 
            ? NetworkImage(item.userPhotoURL!) 
            : null,
          child: item.userPhotoURL == null 
            ? Icon(Icons.person) 
            : null,
        ),
        title: Text(item.title),
        subtitle: Text(_formatTimestamp(item.timestamp)),
        trailing: item.mainImageUrl != null
          ? Image.network(
              item.mainImageUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
          : null,
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
    return 'Ahora';
  }
}
```

---

### Buscar usuarios

```dart
class UserSearchScreen extends StatefulWidget {
  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _profileService = UserProfileService();
  final _searchController = TextEditingController();
  List<UserProfile> _results = [];
  bool _isSearching = false;
  
  void _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    
    setState(() => _isSearching = true);
    
    try {
      final results = await _profileService.searchUsers(query);
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: _isSearching
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final user = _results[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                  child: user.photoURL == null ? Icon(Icons.person) : null,
                ),
                title: Text(user.displayNameOrEmail),
                subtitle: user.ubicacion != null 
                  ? Text(user.ubicacion!)
                  : null,
                onTap: () {
                  // Navegar al perfil del usuario
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userId: user.uid),
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
```

---

## ⚠️ Consideraciones Importantes

### 1. **Migración de Usuarios Existentes**

Si ya tienes usuarios en la base de datos, necesitas agregarles los nuevos campos:

```dart
// Script de migración (ejecutar UNA vez)
Future<void> migrateExistingUsers() async {
  final usersSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .get();
  
  final batch = FirebaseFirestore.instance.batch();
  
  for (final doc in usersSnapshot.docs) {
    final data = doc.data();
    
    // Solo actualizar si no tienen los campos
    if (!data.containsKey('followersCount')) {
      batch.update(doc.reference, {
        'followersCount': 0,
        'followingCount': 0,
        'badgesCount': 0,
        'placesVisitedCount': 0,
        'isPublic': true,
        'showBadges': true,
        'showAlbum': true,
      });
    }
  }
  
  await batch.commit();
  print('Migración completada');
}
```

### 2. **Calcular contadores existentes**

Para los usuarios que ya tienen insignias y lugares visitados:

```dart
Future<void> recalculateUserStats(String userId) async {
  final badges = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('insignias')
    .get();
  
  final places = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('estaciones_visitadas')
    .get();
  
  await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'badgesCount': badges.docs.length,
      'placesVisitedCount': places.docs.length,
    });
}
```

### 3. **Desplegar las nuevas reglas de Firestore**

Asegúrate de desplegar el archivo `firestore.rules` actualizado:

```bash
firebase deploy --only firestore:rules
```

---

## 🎯 Próximos Pasos

Una vez integrados los servicios:
1. ✅ Probar seguir/dejar de seguir usuarios
2. ✅ Verificar que los contadores se actualicen
3. ✅ Confirmar que el feed recibe items nuevos
4. 🔜 Implementar la UI (Fase 3)

---

## 🐛 Troubleshooting

### El feed no se actualiza
- Verifica que estés llamando a `createBadgeFeedItem` o `createPlaceVisitedFeedItem`
- Revisa que el usuario tenga seguidores

### No puedo seguir usuarios
- Verifica las reglas de Firestore
- Asegúrate de que los usuarios tengan los nuevos campos

### Errores de permisos
- Despliega las nuevas reglas de Firestore
- Verifica que el usuario esté autenticado
