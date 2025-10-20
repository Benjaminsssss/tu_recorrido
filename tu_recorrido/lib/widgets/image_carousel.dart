import 'package:flutter/material.dart';
import '../models/place.dart';

class ImageCarousel extends StatefulWidget {
  final List<PlaceImage> images;
  final double aspectRatio;
  final void Function(int)? onPageChanged;
  const ImageCarousel({super.key, required this.images, this.aspectRatio = 16/9, this.onPageChanged});

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
                child: Image.network(
                  img.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  semanticLabel: img.alt,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _current == i ? 12 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: _current == i ? Theme.of(context).primaryColor : Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ],
    );
  }
}
