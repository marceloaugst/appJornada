import '../models/company.dart';
import '../models/vehicle.dart';
import 'mock_data.dart';

class MockApiService {
  static const bool _useMockData = true; // Altere para false para usar API real

  // Simulação de login
  static Future<Map<String, dynamic>> login(String cpf, String password) async {
    await MockData.networkDelay();

    // Simular erro de rede ocasionalmente (5% das vezes)
    if (DateTime.now().millisecond % 20 == 0) {
      throw Exception('Erro de conexão com o servidor');
    }

    // Verificar se CPF está na lista de válidos
    if (!MockData.validCpfs.contains(cpf)) {
      return {'success': false, 'error': 'CPF não encontrado'};
    }

    // Verificar senha
    if (password != MockData.defaultPassword) {
      return {'success': false, 'error': 'Senha incorreta'};
    }

    return MockData.getLoginResponse(cpf);
  }

  // Buscar empresas
  static Future<List<Company>> getCompanies() async {
    await MockData.networkDelay();

    if (!_useMockData) {
      throw Exception('API real não configurada');
    }

    return MockData.companies;
  }

  // Buscar veículos por empresa
  static Future<List<Vehicle>> getVehicles(int companyId) async {
    await MockData.networkDelay();

    if (!_useMockData) {
      throw Exception('API real não configurada');
    }

    return MockData.vehicles.where((v) => v.companyId == companyId).toList();
  }

  // Iniciar jornada
  static Future<Map<String, dynamic>> startJourney({
    required int userId,
    required int companyId,
    required int vehicleId,
    required double latitude,
    required double longitude,
  }) async {
    await MockData.networkDelay();

    // Simular erro ocasional
    if (DateTime.now().millisecond % 15 == 0) {
      return {
        'success': false,
        'error': 'Erro ao iniciar jornada. Tente novamente.',
      };
    }

    return MockData.getJourneyStartResponse();
  }

  // Encerrar jornada
  static Future<Map<String, dynamic>> endJourney({
    required int journeyId,
    required double latitude,
    required double longitude,
  }) async {
    await MockData.networkDelay();

    return MockData.getJourneyEndResponse();
  }

  // Alterar status da jornada
  static Future<Map<String, dynamic>> changeJourneyStatus({
    required int journeyId,
    required String status,
    required double latitude,
    required double longitude,
  }) async {
    await MockData.networkDelay();

    return MockData.getStatusChangeResponse(status);
  }

  // Enviar localização
  static Future<Map<String, dynamic>> sendLocation({
    required int journeyId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    await MockData.networkDelay();

    return {
      'success': true,
      'data': {
        'message': 'Localização enviada com sucesso',
        'timestamp': timestamp.toIso8601String(),
      },
    };
  }

  // Buscar histórico de jornadas
  static Future<List<Map<String, dynamic>>> getJourneyHistory(
    int userId,
  ) async {
    await MockData.networkDelay();

    // Gerar histórico mock
    final now = DateTime.now();
    final history = List.generate(10, (index) {
      final date = now.subtract(Duration(days: index));
      final vehicle = MockData.vehicles[index % MockData.vehicles.length];

      return {
        'id': 1000 + index,
        'date': date.toIso8601String(),
        'vehicle': vehicle.toJson(),
        'startTime': '${(6 + index % 4).toString().padLeft(2, '0')}:00:00',
        'endTime': '${(14 + index % 6).toString().padLeft(2, '0')}:30:00',
        'totalTime': '${(8 + index % 3)}h ${(15 + index * 7) % 60}min',
        'status': index % 3 == 0 ? 'completed' : 'active',
      };
    });

    return history;
  }

  // Validação de CPF mock (sempre retorna true para CPFs da lista)
  static Future<bool> validateCpf(String cpf) async {
    await Future.delayed(Duration(milliseconds: 200));
    return MockData.validCpfs.contains(cpf);
  }

  // Info sobre modo mock
  static bool get isUsingMockData => _useMockData;

  static String get mockInfo =>
      '''
Modo TESTE/DEMONSTRAÇÃO ativo!

Dados disponíveis para teste:
• CPFs válidos: ${MockData.validCpfs.join(', ')}
• Senha padrão: ${MockData.defaultPassword}
• Empresas: ${MockData.companies.length} disponíveis
• Veículos: ${MockData.vehicles.length} disponíveis

Funcionalidades:
✓ Login com dados mock
✓ Seleção de empresa e veículo
✓ Simulação de jornada completa
✓ Todos os botões de status
✓ Cronômetro funcionando
✓ Simulação de erros ocasionais
✓ Delay de rede realista

Para usar dados reais, altere _useMockData para false no arquivo mock_api_service.dart
''';
}
