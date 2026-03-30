import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OcorrenciaImage extends StatelessWidget {
  final String? caminho;
  final double height;
  final double width;
  final BoxFit fit;

  const OcorrenciaImage({
    super.key,
    required this.caminho,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (caminho == null || caminho!.isEmpty) {
      return _buildErrorImage();
    }

    if (caminho!.startsWith('data:image')) {
      try {
        final base64Content = caminho!.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (ctx, err, st) => _buildErrorImage(),
        );
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (caminho!.startsWith('http')) {
      return Image.network(
        caminho!,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (ctx, err, st) => _buildErrorImage(),
      );
    } else {
      // Local File
      final file = File(caminho!);
      return Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (ctx, err, st) => _buildErrorImage(),
      );
    }
  }

  Widget _buildErrorImage() {
    return Container(
      height: height,
      width: width,
      color: AppColors.shimmer,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.textLight,
          size: 40,
        ),
      ),
    );
  }
}
