import 'package:flutter/material.dart';
import '../models/place.dart';

class ImageCarousel extends StatefulWidget {
  final List<PlaceImage> images;
  final double aspectRatio;
  final void Function(int)? onPageChanged;
  const ImageCarousel(
      {super.key,
      required this.images,
      this.aspectRatio = 16 / 9,
      this.onPageChanged});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _current = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              if (widget.onPageChanged != null) widget.onPageChanged!(i);
            },
            itemBuilder: (context, i) {
              final img = widget.images[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GestureDetector(
                  onTap: () {
                    // Abrir visor a pantalla completa comenzando en la imagen i
                    Navigator.of(context).push(PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (ctx, a1, a2) => FullscreenImageViewer(
                        images: widget.images,
                        initialPage: i,
                      ),
                    ));
                  },
                  child: Image(
                    image: img.imageProvider(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    semanticLabel: img.alt,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.broken_image, size: 48)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              widget.images.length,
              (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 12 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? const Color(0xFFC5563A)
                          : const Color(
                              0xFFD9D1C9), // terracota activo, neutro cálido inactivo
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
        ),
      ],
    );
  }
}

class FullscreenImageViewer extends StatefulWidget {
  final List<PlaceImage> images;
  final int initialPage;
  const FullscreenImageViewer(
      {super.key, required this.images, this.initialPage = 0});

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, i) {
                final img = widget.images[i];
                return Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image(
                      image: img.imageProvider(),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      semanticLabel: img.alt,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.black,
                        child: const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white, size: 48)),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Close button
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),

            // Page indicator
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 12 : 8,
                    height: active ? 8 : 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
