import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UniversalImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const UniversalImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Graceful handling of empty or invalid image path
    if (imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: errorWidget ?? const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? Container(
          width: width,
          height: height,
          color: Colors.grey[100],
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: errorWidget ?? const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    } else {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: errorWidget ?? const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
  }
}
