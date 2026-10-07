import 'dart:convert';
import 'lib/services/astro_api_service.dart';

void main() async {
  try {
    final res = await AstroApiService.getLalKitab(ayanamsa: 'LAHIRI');
    print(jsonEncode(res));
  } catch (e) {
    print('Error: $e');
  }
}
