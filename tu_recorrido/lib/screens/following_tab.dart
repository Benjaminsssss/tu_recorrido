import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/feed_service.dart';
import '../models/feed_place_post.dart';

/// Tab "Siguiendo" - Muestra actividad reciente de usuarios seguidos
class FollowingTab extends StatefulWidget {
  const FollowingTab({super.key});

  @override
  State<FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<FollowingTab> {
  final FeedService _feedService = FeedService();

  @override
  void initState() {
    super.initState();
    // Configurar idioma español para timeago
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedPlacePost>>(
      stream: _feedService.getFeedStream(),
      builder: (context, snapshot) {
        // Estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar actividad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        // Sin actividad
        if (posts.isEmpty) {
          return _buildEmptyState(context);
        }

        // Lista de posts con RefreshIndicator
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Refresca el stream
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _FeedPlaceCard(post: posts[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No hay actividad reciente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sigue a otros usuarios para ver su actividad aquí',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card para mostrar un lugar visitado con carrusel de fotos
class _FeedPlaceCard extends StatefulWidget {
  final FeedPlacePost post;

  const _FeedPlaceCard({required this.post});

  @override
  State<_FeedPlaceCard> createState() => _FeedPlaceCardState();
}

class _FeedPlaceCardState extends State<_FeedPlaceCard> {
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Usuario y fecha
          _buildHeader(context),
          
          // Carrusel de imágenes
          _buildImageCarousel(),
          
          // Información del lugar y rating
          _buildPlaceInfo(),
          
          // Descripción/experiencia (solo si existe en la foto actual)
          _buildDescription(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final mostRecentPhoto = widget.post.photos.first;
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.white,
      child: Row(
        children: [
          // Avatar del usuario
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/user-profile/${widget.post.userId}',
              );
            },
            child: Hero(
              tag: 'avatar_${widget.post.userId}_${widget.post.placeId}',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF156A79),
                backgroundImage: widget.post.userPhotoURL != null
                    ? NetworkImage(widget.post.userPhotoURL!)
                    : null,
                child: widget.post.userPhotoURL == null
                    ? const Icon(Icons.person, size: 24, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Nombre y tiempo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/user-profile/${widget.post.userId}',
                    );
                  },
                  child: Text(
                    widget.post.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(mostRecentPhoto.uploadDate, locale: 'es'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        // PageView para el carrusel
        SizedBox(
          width: double.infinity,
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            dragStartBehavior: DragStartBehavior.down,
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemCount: widget.post.photos.length,
            itemBuilder: (context, index) {
              final photo = widget.post.photos[index];
              return Container(
                color: Colors.grey[100],
                child: Image.network(
                  photo.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 3,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        
        // Indicador de página (solo si hay múltiples fotos)
        if (widget.post.photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.6 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.post.photos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPhotoIndex == index
                            ? Colors.white
                            : Colors.white.withAlpha((0.4 * 255).round()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        // Contador de fotos (esquina superior derecha)
        if (widget.post.photos.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.6 * 255).round()),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.collections,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentPhotoIndex + 1}/${widget.post.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          // Icono de ubicación
          Container(
            padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF156A79).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.place,
              size: 20,
              color: Color(0xFF156A79),
            ),
          ),
          const SizedBox(width: 10),
          
          // Nombre del lugar
          Expanded(
            child: Text(
              widget.post.placeName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Rating con estrellas
          if (widget.post.rating != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(5, (index) {
                    if (index < widget.post.rating!.floor()) {
                      return Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[700],
                      );
                    } else if (index < widget.post.rating!.ceil() && 
                               widget.post.rating! % 1 != 0) {
                      return Icon(
                        Icons.star_half,
                        size: 16,
                        color: Colors.amber[700],
                      );
                    } else {
                      return Icon(
                        Icons.star_border,
                        size: 16,
                        color: Colors.grey[400],
                      );
                    }
                  }),
                  const SizedBox(width: 4),
                  Text(
                    widget.post.rating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final currentPhoto = widget.post.photos[_currentPhotoIndex];
    
    // Solo mostrar si la foto actual tiene descripción
    if (currentPhoto.description == null || currentPhoto.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experiencia:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentPhoto.description!,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
