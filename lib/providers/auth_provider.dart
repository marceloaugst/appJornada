import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import '../models/company.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoaded = false;
  User? _user;
  Vehicle? _vehicle;
  Company? _company;
  bool _allowChanges = true; // Sempre permitir mudanças no modo mock
  List<Company> _companies = [];
  String? _errorMessage;

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

      final vehicleData = prefs.getString('vehicle');
      if (vehicleData != null) {
        _vehicle = Vehicle.fromJson(jsonDecode(vehicleData));
      }

      final companyData = prefs.getString('company');
      if (companyData != null) {
        _company = Company.fromJson(jsonDecode(companyData));
      }

      _allowChanges = prefs.getBool('allowChanges') ?? true;

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados armazenados: $e');
      _isLoaded = true;
      notifyListeners();
    }
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
        final companies = await ApiService.fetchCompanies();
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

  Future<bool> login({required String cpf, required String password}) async {
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
        // Login com API real (não implementado)
        throw Exception('API real não configurada');
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
    await _saveUserData();
    notifyListeners();
  }

  Future<List<Vehicle>> getVehiclesForCompany(int companyId) async {
    try {
      if (MockApiService.isUsingMockData) {
        return await MockApiService.getVehicles(companyId);
      } else {
        throw Exception('API real não configurada');
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
}
