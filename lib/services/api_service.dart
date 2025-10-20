import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/company.dart';
import '../models/vehicle.dart';

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

  static Future<List<Vehicle>> fetchVehicles(
    int companyId, {
    String? cpf,
    String? matricula,
    int? currentDriverId, // ID do motorista atual para filtrar
  }) async {
    try {
      print('ApiService: Buscando veículos para empresa ID: $companyId');
      print('ApiService: Motorista atual ID: $currentDriverId');

      // Para empresa ID 1 (WAFRAN), usar database cli_wafran
      String database = 'cli_wafran'; // Sempre usar cli_wafran por enquanto

      // Tentar usar o novo endpoint primeiro (quando estiver disponível na API)
      final requestBody = {
        'tipoConsulta': 'obterListaPlacasFiltrada', // Novo endpoint com filtro
        'banco': database,
      };

      // Adicionar dados do usuário se disponíveis (como no login)
      if (cpf != null) requestBody['cpf'] = cpf;
      if (matricula != null) requestBody['matricula'] = matricula;
      if (currentDriverId != null)
        requestBody['id_motorista_atual'] = currentDriverId.toString();

      print('ApiService: Tentando endpoint filtrado...');
      print('ApiService: Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      print('ApiService: Response status: ${response.statusCode}');

      // Se o novo endpoint não existe ou dá erro, usar fallback
      if (response.statusCode != 200 ||
          response.body.contains('Consulta inválida') ||
          response.body.contains('erro')) {
        print(
          'ApiService: Endpoint filtrado não disponível, usando fallback...',
        );
        return await _fetchVehiclesFallback(
          database,
          cpf,
          matricula,
          currentDriverId,
        );
      }

      final data = jsonDecode(response.body);
      print('ApiService: Dados decodificados (endpoint filtrado): $data');

      if (data is List) {
        print('ApiService: É uma lista com ${data.length} itens (já filtrada)');
        final vehicles = data
            .map<Vehicle>((item) => Vehicle.fromJson(item))
            .toList();
        print('ApiService: Veículos mapeados: ${vehicles.length}');
        return vehicles;
      }

      return [];
    } catch (e) {
      print('ApiService: Erro no endpoint filtrado, tentando fallback: $e');
      String database = 'cli_wafran'; // Definir database para fallback
      return await _fetchVehiclesFallback(
        database,
        cpf,
        matricula,
        currentDriverId,
      );
    }
  }

  static Future<List<Vehicle>> _fetchVehiclesFallback(
    String database,
    String? cpf,
    String? matricula,
    int? currentDriverId,
  ) async {
    try {
      print('ApiService: Usando fallback com endpoint atual...');

      // Fallback para endpoint atual
      final fallbackRequestBody = {
        'tipoConsulta': 'obterListaPlacas',
        'banco': database,
      };

      if (cpf != null) fallbackRequestBody['cpf'] = cpf;
      if (matricula != null) fallbackRequestBody['matricula'] = matricula;

      print('ApiService: Fallback request body: $fallbackRequestBody');

      final fallbackResponse = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(fallbackRequestBody),
          )
          .timeout(timeout);

      print(
        'ApiService: Fallback response status: ${fallbackResponse.statusCode}',
      );

      if (fallbackResponse.statusCode == 200) {
        final data = jsonDecode(fallbackResponse.body);
        print('ApiService: Dados decodificados (fallback): $data');

        if (data is List) {
          print('ApiService: É uma lista com ${data.length} itens');

          // Simular dados de id_pessoal para demonstração
          // Na produção, o endpoint PHP deveria retornar esses dados
          final vehiclesWithDriverData = data.map((item) {
            // Adicionar campo simulado id_pessoal
            final vehicleData = Map<String, dynamic>.from(item);

            // Simular alguns veículos vinculados e outros livres
            final vehicleId = vehicleData['id_veiculo'];
            if (vehicleId != null) {
              // Simular que alguns veículos estão vinculados a outros motoristas
              if (vehicleId == 1873561)
                vehicleData['id_pessoal'] = 99; // Outro motorista
              else if (vehicleId == 2201061)
                vehicleData['id_pessoal'] = 88; // Outro motorista
              else if (vehicleId == 1873570)
                vehicleData['id_pessoal'] = currentDriverId; // Motorista atual
              else if (vehicleId == 1572382)
                vehicleData['id_pessoal'] = 77; // Outro motorista
              // Outros veículos ficam sem id_pessoal (livres)
            }

            return vehicleData;
          }).toList();

          // Aplicar filtro: só mostrar veículos livres OU do motorista atual
          final filteredVehicles = vehiclesWithDriverData.where((vehicleData) {
            final driverId = vehicleData['id_pessoal'];
            return driverId == null || driverId == currentDriverId;
          }).toList();

          print(
            'ApiService: Veículos antes do filtro: ${vehiclesWithDriverData.length}',
          );
          print('ApiService: Veículos após filtro: ${filteredVehicles.length}');
          print(
            'ApiService: Filtro aplicado para motorista ID: $currentDriverId',
          );

          final vehicles = filteredVehicles
              .map<Vehicle>((item) => Vehicle.fromJson(item))
              .toList();
          print('ApiService: Veículos mapeados: ${vehicles.length}');
          return vehicles;
        }
      }

      return [];
    } catch (e) {
      print('ApiService: Erro no fallback: $e');
      throw Exception('Erro ao buscar veículos: $e');
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tipoConsulta': 'testeConexao'}),
          )
          .timeout(Duration(seconds: 5)); // Timeout menor para teste rápido

      return response.statusCode == 200;
    } catch (e) {
      return false;
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

  /// Busca o veículo atualmente vinculado ao motorista no banco de dados
  static Future<Vehicle?> fetchLinkedVehicle({
    required String database,
    required String cpf,
    required String matricula,
    required int driverId,
  }) async {
    try {
      print(
        'ApiService: Buscando veículo vinculado para motorista ID: $driverId',
      );

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tipoConsulta': 'obterVeiculoVinculado',
              'id_motorista': driverId,
              'banco': database,
              'cpf': cpf,
              'matricula': matricula,
            }),
          )
          .timeout(timeout);

      print(
        'ApiService: Response status para veículo vinculado: ${response.statusCode}',
      );
      print('ApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ApiService: Dados do veículo vinculado: $data');

        // Se retornou dados válidos, criar objeto Vehicle
        if (data != null && data is Map<String, dynamic> && data.isNotEmpty) {
          return Vehicle.fromJson(data);
        }

        // Se não há veículo vinculado, retorna null
        return null;
      } else {
        print(
          'ApiService: Erro na consulta do veículo vinculado: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('ApiService: Erro ao buscar veículo vinculado: $e');
      // Em caso de erro, tentar buscar localmente entre os veículos disponíveis
      try {
        // Precisamos do companyId, vamos usar um valor padrão ou buscar das empresas
        final companies = await fetchCompanies();
        if (companies.isNotEmpty && companies.first.id != null) {
          final vehicles = await fetchVehicles(
            companies.first.id!, // Usar primeira empresa como fallback
            cpf: cpf,
            matricula: matricula,
            currentDriverId: driverId,
          );

          // Buscar veículo que tem o driverId como id_pessoal
          final linkedVehicle = vehicles
              .where((v) => v.driverId == driverId)
              .firstOrNull;
          print(
            'ApiService: Veículo vinculado encontrado localmente: ${linkedVehicle?.plate}',
          );
          return linkedVehicle;
        }
        return null;
      } catch (fallbackError) {
        print(
          'ApiService: Erro no fallback para buscar veículo vinculado: $fallbackError',
        );
        return null;
      }
    }
  }
}
