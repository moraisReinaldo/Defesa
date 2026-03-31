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
      return _buildError();
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
          errorBuilder: (ctx, err, st) => _buildError(),
        );
      } catch (e) {
        return _buildError();
      }
    } else if (caminho!.startsWith('http')) {
      return Image.network(
        caminho!,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _buildLoading();
        },
        errorBuilder: (ctx, err, st) => _buildError(),
      );
    } else {
      // Local File
      final file = File(caminho!);
      return Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (ctx, err, st) => _buildError(),
      );
    }
  }

  Widget _buildLoading() {
    return Container(
      height: height,
      width: width,
      color: AppColors.shimmer,
      child:  const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: height,
      width: width,
      color: AppColors.borderLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: AppColors.textLight, size: 32),
          SizedBox(height: 8),
          Text('Erro ao carregar imagem', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
