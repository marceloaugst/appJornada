import '../models/user.dart';
import '../models/company.dart';
import '../models/vehicle.dart';

class MockData {
  // Lista de empresas mock
  static final List<Company> companies = [
    Company(
      id: 1,
      name: 'Transportes São Paulo LTDA',
      code: 'TSP001',
      key: 'TSP001',
      value: 'Transportes São Paulo LTDA',
    ),
    Company(
      id: 2,
      name: 'Logística Rio de Janeiro S.A.',
      code: 'LRJ002',
      key: 'LRJ002',
      value: 'Logística Rio de Janeiro S.A.',
    ),
    Company(
      id: 3,
      name: 'Frota Minas Gerais EIRELI',
      code: 'FMG003',
      key: 'FMG003',
      value: 'Frota Minas Gerais EIRELI',
    ),
    Company(
      id: 4,
      name: 'Transportadora Nacional Express',
      code: 'TNE004',
      key: 'TNE004',
      value: 'Transportadora Nacional Express',
    ),
    Company(
      id: 5,
      name: 'Cargo Sul Distribuidora',
      code: 'CSD005',
      key: 'CSD005',
      value: 'Cargo Sul Distribuidora',
    ),
  ];

  // Lista de veículos mock
  static final List<Vehicle> vehicles = [
    Vehicle(id: 1, plate: 'ABC-1234', model: 'Volvo FH 540', companyId: 1),
    Vehicle(id: 2, plate: 'DEF-5678', model: 'Scania R 450', companyId: 1),
    Vehicle(
      id: 3,
      plate: 'GHI-9012',
      model: 'Mercedes-Benz Actros',
      companyId: 2,
    ),
    Vehicle(id: 4, plate: 'JKL-3456', model: 'MAN TGX 28.480', companyId: 2),
    Vehicle(id: 5, plate: 'MNO-7890', model: 'Iveco Stralis', companyId: 3),
    Vehicle(id: 6, plate: 'PQR-1357', model: 'DAF XF 105', companyId: 3),
    Vehicle(id: 7, plate: 'STU-2468', model: 'Ford Cargo 2429', companyId: 4),
    Vehicle(
      id: 8,
      plate: 'VWX-9753',
      model: 'Volkswagen Constellation',
      companyId: 5,
    ),
  ];

  // Usuários mock com diferentes perfis
  static final List<User> users = [
    User(id: 1, name: 'João Silva', cpf: '12345678901', companyId: 1),
    User(id: 2, name: 'Maria Santos', cpf: '98765432100', companyId: 1),
    User(id: 3, name: 'Pedro Oliveira', cpf: '11111111111', companyId: 2),
    User(id: 4, name: 'Ana Costa', cpf: '22222222222', companyId: 3),
    User(id: 5, name: 'Carlos Ferreira', cpf: '33333333333', companyId: 4),
  ];

  // CPFs válidos para teste (sem validação real de dígito verificador)
  static final List<String> validCpfs = [
    '12345678901',
    '98765432100',
    '11111111111',
    '22222222222',
    '33333333333',
    '55555555555',
    '77777777777',
    '88888888888',
    '99999999999',
  ];

  // Senhas padrão para teste
  static const String defaultPassword = '123456';

  // Dados de resposta da API mock
  static Map<String, dynamic> getLoginResponse(String cpf) {
    final user = users.firstWhere(
      (u) => u.cpf == cpf,
      orElse: () => users.first, // Retorna o primeiro usuário se não encontrar
    );

    final company = companies.firstWhere(
      (c) => c.id == user.companyId,
      orElse: () => companies.first,
    );

    return {
      'success': true,
      'data': {
        'user': user.toJson(),
        'company': company.toJson(),
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      },
    };
  }

  static Map<String, dynamic> getCompaniesResponse() {
    return {'success': true, 'data': companies.map((c) => c.toJson()).toList()};
  }

  static Map<String, dynamic> getVehiclesResponse(int companyId) {
    final companyVehicles = vehicles
        .where((v) => v.companyId == companyId)
        .toList();
    return {
      'success': true,
      'data': companyVehicles.map((v) => v.toJson()).toList(),
    };
  }

  static Map<String, dynamic> getJourneyStartResponse() {
    return {
      'success': true,
      'data': {
        'journeyId': DateTime.now().millisecondsSinceEpoch,
        'startTime': DateTime.now().toIso8601String(),
        'message': 'Jornada iniciada com sucesso!',
      },
    };
  }

  static Map<String, dynamic> getJourneyEndResponse() {
    return {
      'success': true,
      'data': {
        'endTime': DateTime.now().toIso8601String(),
        'totalTime': '08:30:15',
        'message': 'Jornada encerrada com sucesso!',
      },
    };
  }

  static Map<String, dynamic> getStatusChangeResponse(String status) {
    return {
      'success': true,
      'data': {
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Status alterado para $status',
      },
    };
  }

  // Simular delay de rede
  static Future<void> networkDelay() async {
    await Future.delayed(
      Duration(milliseconds: 500 + (DateTime.now().millisecond % 1000)),
    );
  }
}
