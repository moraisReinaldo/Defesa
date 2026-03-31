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
      
      final response = await http.get(url, headers: {
        'User-Agent': 'DefesaCivilApp/1.0', // Nominatim requer User-Agent
        'Accept-Language': 'pt-BR',
      }).timeout( const Duration(seconds: 10));

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
}
