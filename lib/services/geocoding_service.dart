import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeocodingService {
  // OSM Nominatim API (Free and Open)
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';

  /// Busca o nome da cidade a partir das coordenadas Latitude e Longitude
  Future<String?> obterCidade(double lat, double lng) async {
    try {
      final url = Uri.parse('$_baseUrl?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1');
      
      final headers = {
        'Accept-Language': 'pt-BR',
      };
      if (!kIsWeb) {
        headers['User-Agent'] = 'DefesaCivilApp/1.0'; // Nominatim requer User-Agent (mas web não permite alterar)
      }

      final response = await http.get(url, headers: headers).timeout( const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address != null) {
          // Tenta pegar a cidade de vários campos possíveis retornados pelo Nominatim
          return address['city'] ?? 
                 address['town'] ?? 
                 address['village'] ?? 
                 address['municipality'] ?? 
                 address['suburb'] ?? 
                 address['city_district'];
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro no reverse geocoding: $e');
    }
    return null;
  }

  /// Busca as coordenadas a partir de um endereço
  Future<Map<String, double>?> obterCoordenadas(String endereco) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(endereco)}&limit=1');
      
      final headers = {
        'Accept-Language': 'pt-BR',
      };
      if (!kIsWeb) {
        headers['User-Agent'] = 'DefesaCivilApp/1.0';
      }

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'] ?? '');
          final lon = double.tryParse(data[0]['lon'] ?? '');
          if (lat != null && lon != null) {
            return {'lat': lat, 'lng': lon};
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro no forward geocoding: $e');
    }
    return null;
  }

  /// Busca múltiplos endereços correspondentes (geocoding com sugestões)
  Future<List<EnderecoSugestao>> buscarEnderecos(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&countrycodes=br&limit=5&addressdetails=1',
      );

      final headers = {
        'Accept-Language': 'pt-BR',
      };
      if (!kIsWeb) {
        headers['User-Agent'] = 'DefesaCivilApp/1.0';
      }

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          return EnderecoSugestao(
            displayNome: item['display_name'] ?? '',
            lat: lat,
            lng: lon,
          );
        }).where((e) => e.lat != 0.0 && e.lng != 0.0).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar endereços: $e');
    }
    return [];
  }
}

class EnderecoSugestao {
  final String displayNome;
  final double lat;
  final double lng;

  EnderecoSugestao({
    required this.displayNome,
    required this.lat,
    required this.lng,
  });
}
