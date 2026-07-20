import 'package:flutter/material.dart';

import '../../../domain/model/photo.dart';

class PhotoWidget extends StatelessWidget {
  const PhotoWidget({super.key, required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(photo.imageUrl, fit: BoxFit.cover),
    );
  }
}
