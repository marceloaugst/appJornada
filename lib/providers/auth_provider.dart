import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import '../models/company.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart';
import '../services/vehicle_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoaded = false;
  User? _user;
  Vehicle? _vehicle;
  Company? _company;
  bool _allowChanges = true; // Sempre permitir mudanças no modo mock
  List<Company> _companies = [];
  String? _errorMessage;

  // Guardar dados do último login para usar na busca de veículos
  String? _lastLoginCpf;
  String? _lastLoginMatricula;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  User? get user => _user;
  Vehicle? get vehicle => _vehicle;
  Company? get company => _company;
  bool get allowChanges => _allowChanges;
  List<Company> get companies => _companies;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _user != null && _company != null;

  AuthProvider() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userData = prefs.getString('user');
      if (userData != null) {
        _user = User.fromJson(jsonDecode(userData));
      }

      final companyData = prefs.getString('company');
      if (companyData != null) {
        _company = Company.fromJson(jsonDecode(companyData));
      }

      _allowChanges = prefs.getBool('allowChanges') ?? true;

      // IMPORTANTE: Ao invés de carregar do cache local, sempre verificar no banco
      // Isso garante que o estado local esteja sincronizado com o servidor
      await _syncVehicleFromDatabase();

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados armazenados: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Sincroniza o veículo do usuário com o banco de dados
  /// Esta é a fonte da verdade para o estado do veículo
  Future<void> _syncVehicleFromDatabase() async {
    try {
      if (_user == null || _company == null) {
        debugPrint(
          'AuthProvider: Usuário ou empresa não carregados, pulando sincronização de veículo',
        );
        return;
      }

      debugPrint(
        'AuthProvider: Sincronizando veículo do banco para usuário ID: ${_user!.id}',
      );

      // Buscar o veículo vinculado no banco de dados
      final linkedVehicleResult = await VehicleService.getLinkedVehicle(
        driverId: _user!.id!,
        database:
            _user!.database ??
            _company!.key, // Usar database do usuário ou código da empresa
        cpf: _user!.cpf ?? '',
        matricula: _user!.matricula ?? '',
      );

      if (linkedVehicleResult != null &&
          linkedVehicleResult['success'] == true) {
        final vehicleData = linkedVehicleResult['vehicle'];
        _vehicle = Vehicle.fromJson(vehicleData);
        debugPrint(
          'AuthProvider: Veículo vinculado encontrado no banco: ${_vehicle?.plate}',
        );

        // Atualizar cache local com dados do banco
        await _saveVehicleToCache(_vehicle!);
      } else {
        debugPrint(
          'AuthProvider: Nenhum veículo vinculado encontrado no banco',
        );
        _vehicle = null;

        // Limpar cache local se não há veículo vinculado no banco
        await _clearVehicleFromCache();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Erro ao sincronizar veículo do banco: $e');
      // Em caso de erro, carregar do cache como fallback
      await _loadVehicleFromCache();
    }
  }

  /// Carrega o veículo do cache local (fallback em caso de erro)
  Future<void> _loadVehicleFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehicleData = prefs.getString('vehicle');
      if (vehicleData != null) {
        debugPrint(
          'AuthProvider: Carregando dados de veículo do cache: $vehicleData',
        );
        _vehicle = Vehicle.fromJson(jsonDecode(vehicleData));
        debugPrint(
          'AuthProvider: Veículo carregado do cache: ${_vehicle?.plate}, DriverID: ${_vehicle?.driverId}',
        );
      } else {
        debugPrint('AuthProvider: Nenhum veículo salvo encontrado no cache');
        _vehicle = null;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erro ao carregar veículo do cache: $e');
      _vehicle = null;
    }
  }

  /// Salva o veículo no cache local (SharedPreferences)
  Future<void> _saveVehicleToCache(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicle', jsonEncode(vehicle.toJson()));
    await prefs.setString('@placa', vehicle.plate ?? '');
    if (vehicle.id != null) {
      await prefs.setString('@idVeiculo', vehicle.id.toString());
    }
  }

  /// Remove o veículo do cache local
  Future<void> _clearVehicleFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vehicle');
    await prefs.remove('@placa');
    await prefs.remove('@idVeiculo');
  }

  Future<void> loadCompanies() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Use mock data se disponível
      if (MockApiService.isUsingMockData) {
        final companies = await MockApiService.getCompanies();
        _companies = companies;
      } else {
        debugPrint('Carregando empresas da API real...');
        final companies = await ApiService.fetchCompanies();
        debugPrint('Empresas carregadas: ${companies.length}');
        _companies = companies;
      }
    } catch (e) {
      debugPrint('Erro ao carregar empresas: $e');
      _errorMessage = 'Erro ao carregar empresas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String cpf,
    required String password,
    Company? company, // Empresa pode ser passada como parâmetro
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Use mock login se disponível
      if (MockApiService.isUsingMockData) {
        final result = await MockApiService.login(cpf, password);

        if (result['success'] == true) {
          final data = result['data'];
          _user = User.fromJson(data['user']);
          _company = Company.fromJson(data['company']);

          await _saveUserData();
          return true;
        } else {
          _errorMessage = result['error'] ?? 'Erro no login';
          return false;
        }
      } else {
        // Login com API real
        try {
          // Se uma empresa foi passada como parâmetro, usa ela temporariamente
          Company? companyToUse = company ?? _company;

          // Se ainda não há empresa, vamos tentar fazer login sem especificar empresa
          // ou usar um código padrão que funcione com a API
          String database = '';

          if (companyToUse != null) {
            // Tenta diferentes campos da empresa como database
            // Prioridade: code -> key -> name
            database =
                companyToUse.code ??
                (companyToUse.key.isNotEmpty ? companyToUse.key : null) ??
                companyToUse.name ??
                '';
          }

          debugPrint('Tentando login com API real...');
          debugPrint('CPF: $cpf');
          debugPrint('Matrícula: $password');
          debugPrint('Database: $database');

          // Guardar dados do login para usar depois
          _lastLoginCpf = cpf;
          _lastLoginMatricula = password;
          debugPrint(
            'Empresa passada como parâmetro: ${company?.name} (ID: ${company?.id})',
          );

          final result = await ApiService.login(
            cpf: cpf,
            matricula: password, // matricula vem do campo password
            database: database,
          );

          debugPrint('Resposta da API: $result');

          // A resposta pode variar, vamos verificar diferentes formatos possíveis
          if (result['success'] == true ||
              result['status'] == 'success' ||
              result.containsKey('id_pessoal') ||
              result.containsKey('user') ||
              (result.containsKey('erro') && result['erro'] == false)) {
            // Se tem um objeto 'user' dentro da resposta
            if (result.containsKey('user')) {
              _user = User.fromJson(result['user']);
            } else if (result.containsKey('resultado')) {
              // API real retorna dados do usuário em 'resultado'
              _user = User.fromJson(result['resultado']);
            } else {
              // Cria o usuário a partir da resposta direta
              _user = User.fromJson(result);
            }

            // Se tem uma empresa na resposta, usa ela
            if (result.containsKey('company') && _company == null) {
              _company = Company.fromJson(result['company']);
            }

            // Lógica simplificada: sempre usar database se disponível,
            // caso contrário usar company passada como parâmetro
            debugPrint('DEBUG: Verificando empresa...');
            debugPrint('DEBUG: company != null: ${company != null}');
            debugPrint('DEBUG: database.isNotEmpty: ${database.isNotEmpty}');
            debugPrint('DEBUG: database value: "$database"');

            // Se há database válida, sempre criar empresa baseada nela
            if (database.isNotEmpty) {
              debugPrint('Criando empresa baseada na database: $database');
              _company = _createCompanyFromDatabase(database);
              debugPrint(
                'Empresa criada: ${_company?.name} (ID: ${_company?.id})',
              );
            }
            // Se não há database mas há company, usar ela
            else if (company != null) {
              _company = company;
              debugPrint(
                'Empresa definida a partir do parâmetro: ${company.name} (ID: ${company.id})',
              );
            }
            // Se não há nem database nem company
            else {
              debugPrint('Nenhuma empresa ou database disponível');
            }

            debugPrint('Estado final do AuthProvider após login:');
            debugPrint('- Usuário: ${_user?.name}');
            debugPrint('- Empresa: ${_company?.name} (ID: ${_company?.id})');

            await _saveUserData();
            return true;
          } else {
            // Verifica diferentes campos de erro
            String errorMsg = 'Credenciais inválidas';
            if (result.containsKey('erro') && result['erro'] == true) {
              errorMsg = result['mensagem'] ?? errorMsg;
            } else if (result.containsKey('error')) {
              errorMsg = result['error'] ?? errorMsg;
            } else if (result.containsKey('message')) {
              errorMsg = result['message'] ?? errorMsg;
            }

            _errorMessage = errorMsg;
            return false;
          }
        } catch (apiError) {
          // Trata erros específicos da API (como problemas de conexão com banco)
          debugPrint('Erro na API real: $apiError');

          String errorMsg = 'Erro no servidor';
          String fullError = apiError.toString();

          // Se for erro de conexão com banco, mostra mensagem mais específica
          if (fullError.contains('connection') ||
              fullError.contains('SQLSTATE')) {
            if (fullError.contains('não existe o banco de dados')) {
              errorMsg =
                  'Banco de dados da empresa não encontrado. Verifique se a empresa está correta.';
            } else if (fullError.contains('port 5432')) {
              errorMsg =
                  'Servidor de banco de dados indisponível. Tente novamente mais tarde.';
            } else {
              errorMsg = 'Erro de conexão com banco de dados.';
            }
          } else if (fullError.contains('Falha na requisição')) {
            errorMsg = 'Falha na comunicação com servidor.';
          } else {
            errorMsg = 'Erro no servidor: ${fullError}';
          }

          _errorMessage = errorMsg;
          return false;
        }
      }
    } catch (e) {
      debugPrint('Erro no login: $e');
      _errorMessage = 'Erro no login: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCompany(Company company) async {
    _company = company;
    await _saveUserData();
    notifyListeners();
  }

  Future<void> setVehicle(Vehicle vehicle) async {
    _vehicle = vehicle;
    // Salvar no cache local
    await _saveVehicleToCache(vehicle);
    notifyListeners();
  }

  /// Força uma nova sincronização com o banco de dados
  /// Útil para garantir que o estado local está correto
  Future<void> refreshVehicleFromDatabase() async {
    debugPrint('AuthProvider: Forçando sincronização com banco de dados');
    await _syncVehicleFromDatabase();
  }

  /// Nova função para vincular veículo com validação e persistência no servidor
  Future<Map<String, dynamic>> linkVehicleToDriver(Vehicle vehicle) async {
    debugPrint('AuthProvider: Iniciando linkVehicleToDriver');
    debugPrint('AuthProvider: Vehicle received: $vehicle');
    debugPrint('AuthProvider: User: $_user');

    if (_user == null) {
      return {'success': false, 'message': 'Usuário não existe'};
    }

    if (_user?.id == null) {
      return {'success': false, 'message': 'Usuário não está logado (ID null)'};
    }

    if (vehicle.plate == null || vehicle.plate!.isEmpty) {
      return {'success': false, 'message': 'Placa do veículo não informada'};
    }

    debugPrint('AuthProvider: Vinculando veículo ${vehicle.plate} no servidor');
    debugPrint(
      'AuthProvider: Dados - plate: ${vehicle.plate}, userId: ${_user!.id}, userType: ${_user!.id.runtimeType}',
    );

    try {
      // Validar se os dados necessários estão corretos
      final userId = _user!.id;
      final vehiclePlate = vehicle.plate;

      if (userId == null) {
        return {'success': false, 'message': 'ID do usuário é null'};
      }

      if (vehiclePlate == null || vehiclePlate.isEmpty) {
        return {'success': false, 'message': 'Placa do veículo é inválida'};
      }

      debugPrint(
        'AuthProvider: Chamando VehicleService com userId: $userId (${userId.runtimeType}), plate: $vehiclePlate',
      );

      // Usar API real para vincular veículo no banco de dados
      final result = await VehicleService.linkVehicleToDriver(
        vehiclePlate: vehiclePlate,
        driverId: userId,
        database: 'cli_wafran',
        previousVehiclePlate:
            _vehicle?.plate, // Desvincular anterior se existir
      );

      if (result['success'] == true) {
        // Atualizar veículo localmente após sucesso no servidor (IGUAL AO REACT)
        final vehicleId =
            result['vehicleId'] ?? vehicle.id; // ID retornado pela API

        final updatedVehicle = Vehicle(
          id: vehicleId,
          plate: vehicle.plate,
          model: vehicle.model,
          companyId: vehicle.companyId,
          driverId: _user!.id, // Marcar como vinculado ao motorista atual
        );

        await setVehicle(updatedVehicle);

        // Salvar dados adicionais seguindo padrão do React
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('@placa', vehicle.plate ?? '');
        await prefs.setInt('@idVeiculo', vehicleId ?? 0);

        debugPrint(
          'AuthProvider: Veículo ${vehicle.plate} vinculado com sucesso no servidor e localmente',
        );
        debugPrint('AuthProvider: ID do veículo salvo: $vehicleId');

        return {
          'success': true,
          'message':
              result['message'] ??
              'Veículo ${vehicle.plate} vinculado com sucesso!',
          'vehicleId': vehicleId,
        };
      } else {
        // Se a API não suporta vinculação, fazer apenas localmente
        if (result['fallback_required'] == true ||
            result['error']?.toString().contains('endpoint') == true ||
            result['error']?.toString().contains('null') == true ||
            result['error'] == 'endpoint_not_available') {
          debugPrint(
            'AuthProvider: API não suporta vinculação (${result['message']}), fazendo localmente',
          );

          // Criar veículo atualizado com driverId
          final updatedVehicle = Vehicle(
            id: vehicle.id,
            plate: vehicle.plate,
            model: vehicle.model,
            companyId: vehicle.companyId,
            driverId: _user!.id, // Marcar como vinculado ao motorista atual
          );

          await setVehicle(updatedVehicle);

          debugPrint(
            'AuthProvider: Veículo ${vehicle.plate} vinculado localmente (API não suporta vinculação)',
          );

          return {
            'success': true,
            'message':
                '✅ Veículo ${vehicle.plate} vinculado com sucesso!\n\n📱 Vinculação feita localmente\n(A API não possui endpoint de vinculação)',
          };
        }

        return result;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erro ao vincular veículo: $e');
      return {'success': false, 'message': 'Erro ao vincular veículo: $e'};
    }
  }

  /// Nova função para desvincular veículo com persistência no servidor
  Future<Map<String, dynamic>> unlinkVehicleFromDriver() async {
    if (_user?.id == null || _vehicle == null) {
      return {'success': false, 'message': 'Não há veículo para desvincular'};
    }

    if (_vehicle!.plate == null) {
      return {'success': false, 'message': 'Placa do veículo não informada'};
    }

    final currentVehicle = _vehicle!;
    debugPrint(
      'AuthProvider: Desvinculando veículo ${currentVehicle.plate} no servidor',
    );

    try {
      // Usar API real para desvincular veículo no banco de dados
      final result = await VehicleService.unlinkVehicleFromDriver(
        vehiclePlate: currentVehicle.plate!,
        driverId: _user!.id!,
        database: 'cli_wafran',
      );

      if (result['success'] == true) {
        // Limpar dados do veículo seguindo PADRÃO DO REACT
        await clearVehicle();

        // Limpar dados salvos no SharedPreferences (igual ao AsyncStorage do React)
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('@placa');
        await prefs.remove('@idVeiculo');

        debugPrint(
          'AuthProvider: Veículo ${currentVehicle.plate} desvinculado com sucesso no servidor e localmente',
        );

        return {
          'success': true,
          'message':
              result['message'] ??
              'Veículo ${currentVehicle.plate} desvinculado com sucesso!',
        };
      } else {
        return result;
      }
    } catch (e) {
      debugPrint('AuthProvider: Erro ao desvincular veículo: $e');
      return {'success': false, 'message': 'Erro ao desvincular veículo: $e'};
    }
  }

  Future<void> clearVehicle() async {
    debugPrint('AuthProvider: Limpando dados do veículo...');

    _vehicle = null;
    await _saveUserData();

    // Limpar também dados do SharedPreferences (compatibilidade React)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('@placa');
    await prefs.remove('@idVeiculo');

    debugPrint('AuthProvider: Dados do veículo limpos completamente');
    notifyListeners();
  }

  /// Limpa TODOS os dados de vinculação - use para resetar estado
  Future<void> clearAllVehicleData() async {
    debugPrint('AuthProvider: Limpando TODOS os dados de veículo...');

    _vehicle = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vehicle'); // Dados principais
    await prefs.remove('@placa'); // Compatibilidade React
    await prefs.remove('@idVeiculo'); // Compatibilidade React

    await _saveUserData();

    debugPrint('AuthProvider: TODOS os dados de veículo foram removidos');
    notifyListeners();
  }

  Future<List<Vehicle>> getVehiclesForCompany(int companyId) async {
    try {
      debugPrint('AuthProvider: Buscando veículos para empresa ID: $companyId');
      debugPrint(
        'AuthProvider: Usando mock data: ${MockApiService.isUsingMockData}',
      );

      if (MockApiService.isUsingMockData) {
        final vehicles = await MockApiService.getVehicles(companyId);
        debugPrint(
          'AuthProvider: Veículos mock carregados: ${vehicles.length}',
        );
        return vehicles;
      } else {
        // Usar API real para buscar veículos
        debugPrint('AuthProvider: Chamando API real para buscar veículos...');
        debugPrint('AuthProvider: ID do motorista atual: ${_user?.id}');

        final vehicles = await ApiService.fetchVehicles(
          companyId,
          cpf: _lastLoginCpf,
          matricula: _lastLoginMatricula,
          currentDriverId:
              _user?.id, // Passar ID do motorista atual para filtro
        );

        debugPrint(
          'AuthProvider: Veículos da API real (filtrados): ${vehicles.length}',
        );
        for (var vehicle in vehicles) {
          debugPrint(
            'AuthProvider: - ${vehicle.plate} (${vehicle.model}) - DriverID: ${vehicle.driverId}',
          );
        }
        return vehicles;
      }
    } catch (e) {
      debugPrint('Erro ao carregar veículos: $e');
      return [];
    }
  }

  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_user != null) {
        await prefs.setString('user', jsonEncode(_user!.toJson()));
      }

      if (_vehicle != null) {
        await prefs.setString('vehicle', jsonEncode(_vehicle!.toJson()));
      }

      if (_company != null) {
        await prefs.setString('company', jsonEncode(_company!.toJson()));
      }

      await prefs.setBool('allowChanges', _allowChanges);
    } catch (e) {
      debugPrint('Erro ao salvar dados do usuário: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _user = null;
      _vehicle = null;
      _company = null;
      _allowChanges = true;
      _companies = [];
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Company? _createCompanyFromDatabase(String database) {
    // Mapeia códigos de database conhecidos para informações da empresa
    switch (database.toLowerCase()) {
      case 'cli_wafran':
        return Company(
          id: 1, // ID fixo para WAFRAN
          name: 'WAFRAN TRANSPORTES',
          code: 'cli_wafran',
          key: 'cli_wafran',
          value: 'WAFRAN TRANSPORTES',
        );
      // Adicione mais empresas conforme necessário
      default:
        // Para databases desconhecidos, cria uma empresa genérica
        return Company(
          id: 999,
          name: database.toUpperCase(),
          code: database,
          key: database,
          value: database.toUpperCase(),
        );
    }
  }
}
