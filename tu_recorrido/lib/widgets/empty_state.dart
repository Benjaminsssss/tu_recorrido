import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? svgString;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double width;
  final double height;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.svgString,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.width = 220,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    final image = svgString != null
        ? SvgPicture.string(svgString!,
            width: width, height: height, fit: BoxFit.contain)
        : Icon(icon ?? Icons.landscape,
            size: 64,
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.6));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: image),
          const SizedBox(height: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
