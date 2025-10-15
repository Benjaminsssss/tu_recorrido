import 'package:flutter/material.dart';

class CollectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageAsset;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CollectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 84,
                height: 84,
                child: imageAsset != null
                    ? Image.asset(imageAsset!, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFF3F4F6)),
              ),
            ),
            const SizedBox(width: 12),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
