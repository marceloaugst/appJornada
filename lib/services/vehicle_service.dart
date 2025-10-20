import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class VehicleService {
  static const Duration timeout = Duration(seconds: 30);
  static const String baseUrl = ApiService.baseUrl;

  /// Vincula um veículo a um motorista usando o endpoint correto da API
  ///
  /// Esta função implementa a regra de negócio principal:
  /// 1. Verifica se o veículo está disponível
  /// 2. Atualiza o banco de dados vinculando motorista ao veículo
  /// 3. Retorna sucesso/erro da operação
  static Future<Map<String, dynamic>> linkVehicleToDriver({
    required String vehiclePlate, // Mudança: usar placa ao invés de ID
    required int driverId,
    required String database,
    String? previousVehiclePlate, // Para desvincular veículo anterior
  }) async {
    try {
      print('VehicleService: Iniciando vinculação');
      print(
        'VehicleService: vehiclePlate=$vehiclePlate (${vehiclePlate.runtimeType})',
      );
      print('VehicleService: driverId=$driverId (${driverId.runtimeType})');
      print('VehicleService: database=$database');
      print('VehicleService: previousVehiclePlate=$previousVehiclePlate');

      // Validar parâmetros antes de usar
      if (vehiclePlate.isEmpty) {
        return {
          'success': false,
          'message': 'Placa do veículo não pode estar vazia',
        };
      }

      if (database.isEmpty) {
        return {'success': false, 'message': 'Database não pode estar vazio'};
      }

      print(
        'VehicleService: Validações passaram, vinculando veículo $vehiclePlate ao motorista $driverId',
      );

      // Primeiro, desvincular veículo anterior se existir
      if (previousVehiclePlate != null &&
          previousVehiclePlate.isNotEmpty &&
          previousVehiclePlate != vehiclePlate) {
        print(
          'VehicleService: Desvinculando veículo anterior: $previousVehiclePlate',
        );
        final unlinkResult = await _unlinkVehicleFromDriver(
          vehiclePlate: previousVehiclePlate,
          driverId: driverId,
          database: database,
        );
        print('VehicleService: Resultado da desvinculação: $unlinkResult');
      }

      // Vincular novo veículo usando EXATO endpoint do React
      print('VehicleService: Criando request body...');

      // Usar EXATAMENTE o mesmo formato do React
      final requestBody = <String, dynamic>{
        'tipoConsulta': 'vincularPlaca', // MESMO endpoint do React
        'placa': vehiclePlate, // MESMA ordem dos parâmetros
        'id_pessoal': driverId, // MESMO nome do parâmetro
        'banco': database, // MESMA estrutura
      };

      print('VehicleService: Request body criado: $requestBody');

      final jsonBody = jsonEncode(requestBody);
      print('VehicleService: JSON body: $jsonBody');

      print('VehicleService: Fazendo requisição para: $baseUrl');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonBody,
          )
          .timeout(timeout);

      print('VehicleService: Response status: ${response.statusCode}');
      print('VehicleService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Verificar se o body não é vazio antes de tentar decodificar
        if (response.body.isEmpty || response.body == 'null') {
          print(
            'VehicleService: Resposta vazia ou null - endpoint pode não existir',
          );
          return {
            'success': false,
            'message':
                'Endpoint de vinculação não disponível na API. Usando modo local.',
            'error': 'API returned null/empty response',
          };
        }

        try {
          final responseData = jsonDecode(response.body);
          print('VehicleService: Response data decoded: $responseData');

          // Verificar diferentes tipos de resposta possíveis
          if (responseData is Map<String, dynamic>) {
            // Verificar se é erro de consulta inválida (endpoint não existe)
            if (responseData['error'] != null &&
                responseData['error'].toString().toLowerCase().contains(
                  'consulta inválida',
                )) {
              print(
                'VehicleService: Endpoint de vinculação não disponível na API',
              );
              return {
                'success': false,
                'message': 'API não suporta vinculação de veículos',
                'error': 'endpoint_not_available',
                'fallback_required': true,
              };
            }

            // Verificar se vinculação foi bem-sucedida (MESMA LÓGICA DO REACT)
            if (responseData.containsKey('id')) {
              // Sucesso! Retornou um ID do veículo (igual ao React)
              print(
                'VehicleService: Vinculação bem-sucedida, ID do veículo: ${responseData['id']}',
              );
              return {
                'success': true,
                'message': 'Veículo $vehiclePlate vinculado com sucesso!',
                'data': responseData,
                'vehicleId': responseData['id'], // ID retornado pela API
              };
            } else if (responseData['error'] == null &&
                responseData['status'] != 'error') {
              // Resposta sem erro mas também sem ID (caso genérico)
              return {
                'success': true,
                'message': 'Veículo $vehiclePlate vinculado com sucesso!',
                'data': responseData,
              };
            } else {
              // Erro específico - provável placa já vinculada ou indisponível
              String errorMsg =
                  'Essa placa já está vinculada ou se encontra indisponível.';
              if (responseData['error'] != null) {
                errorMsg = responseData['error'].toString();
              }

              return {
                'success': false,
                'message': errorMsg,
                'error': responseData,
              };
            }
          } else {
            return {
              'success': false,
              'message': 'Formato de resposta inválido da API',
              'error': 'Response não é um Map: $responseData',
            };
          }
        } catch (e) {
          print('VehicleService: Erro ao decodificar JSON: $e');
          return {
            'success': false,
            'message': 'Erro ao processar resposta da API: $e',
            'error': 'JSON decode error: $e',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Erro de comunicação com servidor (${response.statusCode})',
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e, stackTrace) {
      print('VehicleService: Erro ao vincular veículo: $e');
      print('VehicleService: Stack trace: $stackTrace');

      String errorMessage = 'Erro inesperado ao vincular veículo';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Timeout na conexão com o servidor';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Erro de conexão com a internet';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Erro no formato dos dados';
      } else if (e.toString().contains('NoSuchMethodError')) {
        errorMessage = 'Erro interno: método não encontrado - $e';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      };
    }
  }

  /// Desvincula um veículo de um motorista
  static Future<Map<String, dynamic>> unlinkVehicleFromDriver({
    required String vehiclePlate,
    required int driverId,
    required String database,
  }) async {
    return await _unlinkVehicleFromDriver(
      vehiclePlate: vehiclePlate,
      driverId: driverId,
      database: database,
    );
  }

  static Future<Map<String, dynamic>> _unlinkVehicleFromDriver({
    required String vehiclePlate,
    required int driverId,
    required String database,
  }) async {
    try {
      print(
        'VehicleService: Desvinculando veículo $vehiclePlate do motorista $driverId',
      );

      // Usar EXATAMENTE o mesmo formato do React para desvinculação
      final requestBody = <String, dynamic>{
        'tipoConsulta': 'desvincularPlaca', // MESMO endpoint do React
        'placa': vehiclePlate, // MESMA ordem dos parâmetros
        'id_pessoal': driverId, // MESMO nome do parâmetro
        'banco': database, // MESMA estrutura
      };

      print('VehicleService: Unlink request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      print('VehicleService: Unlink response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('VehicleService: Unlink response data: $responseData');

        // Verificar desvinculação seguindo MESMA LÓGICA DO REACT
        if (responseData.containsKey('desvinculado') &&
            responseData['desvinculado'] == true) {
          // Sucesso! Placa desvinculada (igual ao React)
          print('VehicleService: Desvinculação bem-sucedida');
          return {
            'success': true,
            'message': 'Placa desvinculada com sucesso. Selecione uma nova.',
            'data': responseData,
          };
        } else if (responseData['error'] != null) {
          // Erro específico
          return {
            'success': false,
            'message': responseData['error'].toString(),
            'error': responseData,
          };
        } else {
          // Caso padrão - placa já desvinculada
          return {
            'success': false,
            'message': 'Essa placa já se encontra desvinculada',
            'data': responseData,
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Erro de comunicação com servidor (${response.statusCode})',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('VehicleService: Erro ao desvincular veículo: $e');
      return {
        'success': false,
        'message': 'Erro ao desvincular veículo: $e',
        'error': e.toString(),
      };
    }
  }

  /// Verifica o status de vinculação de um veículo
  static Future<Map<String, dynamic>> checkVehicleStatus({
    required int vehicleId,
    required String database,
    required String cpf,
    required String matricula,
  }) async {
    try {
      print('VehicleService: Verificando status do veículo $vehicleId');

      final requestBody = {
        'tipoConsulta': 'verificarStatusVeiculo',
        'banco': database,
        'cpf': cpf,
        'matricula': matricula,
        'id_veiculo': vehicleId,
      };

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': 'Erro ao verificar status do veículo',
        };
      }
    } catch (e) {
      print('VehicleService: Erro ao verificar status: $e');
      return {'success': false, 'message': 'Erro ao verificar status: $e'};
    }
  }

  /// Valida se um motorista pode vincular um veículo específico
  ///
  /// Regras de validação:
  /// 1. Veículo deve existir e estar ativo
  /// 2. Veículo não pode estar vinculado a outro motorista
  /// 3. Motorista deve ter permissões adequadas
  /// 4. Não deve ter jornada ativa em outro veículo
  static Future<Map<String, dynamic>> validateVehicleLinking({
    required int vehicleId,
    required int driverId,
    required String database,
  }) async {
    try {
      print(
        'VehicleService: Validando vinculação veículo $vehicleId para motorista $driverId',
      );

      final requestBody = {
        'tipoConsulta': 'validarVinculacaoVeiculo',
        'banco': database,
        'id_veiculo': vehicleId,
        'id_motorista': driverId,
      };

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'canLink': responseData['can_link'] ?? false,
          'reason': responseData['reason'],
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'canLink': false,
          'reason': 'Erro de comunicação com servidor',
        };
      }
    } catch (e) {
      print('VehicleService: Erro na validação: $e');
      return {
        'success': false,
        'canLink': false,
        'reason': 'Erro na validação: $e',
      };
    }
  }

  /// Busca o veículo atualmente vinculado ao motorista no banco de dados
  /// Retorna o veículo vinculado ou null se não houver vinculação
  static Future<Map<String, dynamic>?> getLinkedVehicle({
    required int driverId,
    required String database,
    required String cpf,
    required String matricula,
  }) async {
    try {
      print(
        'VehicleService: Buscando veículo vinculado para motorista $driverId',
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

      print('VehicleService: Response status: ${response.statusCode}');
      print('VehicleService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('VehicleService: Dados recebidos: $data');

        // Verificar se há dados válidos
        if (data != null && data is Map<String, dynamic> && data.isNotEmpty) {
          // Verificar se é um erro da API
          if (data.containsKey('erro') || data.containsKey('error')) {
            print(
              'VehicleService: API retornou erro: ${data['erro'] ?? data['error']}',
            );
            return null;
          }

          // Retornar os dados do veículo vinculado
          return {'success': true, 'vehicle': data};
        }

        // Se retornou vazio ou null, não há veículo vinculado
        print('VehicleService: Nenhum veículo vinculado encontrado');
        return null;
      } else {
        print('VehicleService: Erro HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('VehicleService: Erro ao buscar veículo vinculado: $e');
      return null;
    }
  }
}
