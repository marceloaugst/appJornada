import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/company.dart';

class ApiService {
  static const String baseUrl =
      'https://homologacao.unitopconsultoria.com.br/corte-sorpan/apiMobileRefatorada.php';
  static const Duration timeout = Duration(seconds: 20);

  static Future<List<Company>> fetchCompanies() async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tipoConsulta': 'obterDadosEmpresas'}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map<Company>((item) => Company.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar empresas: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String cpf,
    required String matricula,
    required String database,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tipoConsulta': 'obterLogin',
              'matricula': matricula,
              'cpf': cpf,
              'banco': database,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha na requisição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro no login: $e');
    }
  }

  static Future<Map<String, dynamic>> saveJourneyEvent({
    required int tipo,
    required String tipoEvento,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = {
        'tipoConsulta': 'salvarEvento',
        'tipo': tipo,
        'tipoEvento': tipoEvento,
        'dataEvento': DateTime.now().toIso8601String(),
      };

      if (latitude != null && longitude != null) {
        body['latitude'] = latitude;
        body['longitude'] = longitude;
      }

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha na requisição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao salvar evento: $e');
    }
  }
}
