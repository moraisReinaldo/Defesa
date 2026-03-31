import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

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

    String path = caminho!;
    
    // Se não for Base64, nem URL absoluta HTTP, nem caminho local absoluto (começando com /)
    // Então assumimos que é um caminho relativo vindo do servidor (ex: uploads/foto.jpg)
    if (!path.startsWith('data:') && !path.startsWith('http') && !path.startsWith('/')) {
      final root = ApiService.getServerRoot();
      path = '$root/$path';
    }

    if (path.startsWith('data:image')) {
      try {
        final base64Content = path.split(',').last;
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
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _buildLoading();
        },
        errorBuilder: (ctx, err, st) {
          if (kDebugMode) print('Erro ao carregar imagem remota ($path): $err');
          return _buildError();
        },
      );
    } else {
      // Local File
      final file = File(path);
      return Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (ctx, err, st) {
          if (kDebugMode) print('Erro ao carregar imagem local ($path): $err');
          return _buildError();
        },
      );
    }
  }

  Widget _buildLoading() {
    return Container(
      height: height,
      width: width,
      color: AppColors.shimmer,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
        ),
      ),
    );
  }

  Widget _buildError() {
    final bool isSmall = height < 100;
    
    return Container(
      height: height,
      width: width,
      color: AppColors.borderLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded, 
              color: AppColors.textLight.withValues(alpha: 0.5), 
              size: isSmall ? 22 : 32
            ),
            if (!isSmall) ...[
              const SizedBox(height: 8),
              const Text(
                'Erro ao carregar imagem', 
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
