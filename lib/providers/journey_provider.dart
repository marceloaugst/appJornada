import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/journey_state.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart';
import '../services/location_service.dart';

class JourneyProvider extends ChangeNotifier {
  bool _isJourneyStarted = false;
  JourneyState _journeyState = JourneyState();
  DateTime? _journeyStartTime;
  DateTime? _currentActivityStartTime;

  // Tempos acumulados em segundos
  int _totalDrivingTime = 0;
  int _totalMealTime = 0;
  int _totalWaitingTime = 0;
  int _totalRestingTime = 0;

  Timer? _timer;
  bool _isSaving = false;
  Position? _currentLocation;

  // Getters
  bool get isJourneyStarted => _isJourneyStarted;
  JourneyState get journeyState => _journeyState;
  DateTime? get journeyStartTime => _journeyStartTime;
  DateTime? get currentActivityStartTime => _currentActivityStartTime;
  int get totalDrivingTime => _totalDrivingTime;
  int get totalMealTime => _totalMealTime;
  int get totalWaitingTime => _totalWaitingTime;
  int get totalRestingTime => _totalRestingTime;
  bool get isSaving => _isSaving;
  Position? get currentLocation => _currentLocation;

  // Tempo atual da atividade em andamento
  int get currentActivityTime {
    if (_currentActivityStartTime == null) return 0;

    final now = DateTime.now();
    final currentSeconds = now.difference(_currentActivityStartTime!).inSeconds;

    switch (_journeyState.currentStatus) {
      case JourneyStatus.driving:
        return _totalDrivingTime + currentSeconds;
      case JourneyStatus.meal:
        return _totalMealTime + currentSeconds;
      case JourneyStatus.waiting:
        return _totalWaitingTime + currentSeconds;
      case JourneyStatus.resting:
        return _totalRestingTime + currentSeconds;
      default:
        return 0;
    }
  }

  JourneyProvider() {
    _loadStoredData();
    _initLocationService();
  }

  Future<void> _initLocationService() async {
    try {
      final position = await LocationService.getCurrentLocation();
      _currentLocation = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
    }
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isJourneyStarted = prefs.getBool('journeyStarted') ?? false;

      final journeyStartTimeMs = prefs.getInt('journeyStartTime');
      if (journeyStartTimeMs != null) {
        _journeyStartTime = DateTime.fromMillisecondsSinceEpoch(
          journeyStartTimeMs,
        );
      }

      final activityStartTimeMs = prefs.getInt('currentActivityStartTime');
      if (activityStartTimeMs != null) {
        _currentActivityStartTime = DateTime.fromMillisecondsSinceEpoch(
          activityStartTimeMs,
        );
      }

      _totalDrivingTime = prefs.getInt('totalDrivingTime') ?? 0;
      _totalMealTime = prefs.getInt('totalMealTime') ?? 0;
      _totalWaitingTime = prefs.getInt('totalWaitingTime') ?? 0;
      _totalRestingTime = prefs.getInt('totalRestingTime') ?? 0;

      // Carregar estado da jornada
      final journeyStateData = prefs.getString('journeyState');
      if (journeyStateData != null) {
        _journeyState = JourneyState.fromJson(jsonDecode(journeyStateData));
      }

      if (_isJourneyStarted) {
        _startTimer();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados da jornada: $e');
    }
  }

  Future<void> startJourney() async {
    if (_isSaving) return;

    try {
      _isSaving = true;
      notifyListeners();

      final now = DateTime.now();
      _isJourneyStarted = true;
      _journeyStartTime = now;
      _journeyState = JourneyState();

      await _saveJourneyData();
      await _saveToApi(1, 'JORNADA');

      _startTimer();
    } catch (e) {
      debugPrint('Erro ao iniciar jornada: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setActivity({
    bool driving = false,
    bool meal = false,
    bool waiting = false,
    bool resting = false,
  }) async {
    if (_isSaving || !_isJourneyStarted) return;

    try {
      _isSaving = true;
      notifyListeners();

      // Salvar tempo da atividade anterior
      await _saveCurrentActivityTime();

      final now = DateTime.now();
      _currentActivityStartTime = now;

      _journeyState = JourneyState(
        direcao: driving,
        refeicao: meal,
        espera: waiting,
        descansar: resting,
      );

      await _saveJourneyData();

      String activityType = 'PAUSA';
      if (driving) {
        activityType = 'DIRECAO';
      } else if (meal) {
        activityType = 'REFEICAO';
      } else if (waiting) {
        activityType = 'ESPERA';
      } else if (resting) {
        activityType = 'DESCANSO';
      }

      await _saveToApi(2, activityType);
    } catch (e) {
      debugPrint('Erro ao definir atividade: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> endJourney() async {
    if (_isSaving) return;

    try {
      _isSaving = true;
      notifyListeners();

      // Salvar tempo da atividade atual
      await _saveCurrentActivityTime();

      _journeyState = _journeyState.copyWith(encerrar: true);
      _timer?.cancel();

      await _saveToApi(3, 'ENCERRAR');
      await _clearJourneyData();

      _isJourneyStarted = false;
      _journeyStartTime = null;
      _currentActivityStartTime = null;
      _totalDrivingTime = 0;
      _totalMealTime = 0;
      _totalWaitingTime = 0;
      _totalRestingTime = 0;
      _journeyState = JourneyState();
    } catch (e) {
      debugPrint('Erro ao encerrar jornada: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _saveCurrentActivityTime() async {
    if (_currentActivityStartTime == null) return;

    final now = DateTime.now();
    final timeSpent = now.difference(_currentActivityStartTime!).inSeconds;

    switch (_journeyState.currentStatus) {
      case JourneyStatus.driving:
        _totalDrivingTime += timeSpent;
        break;
      case JourneyStatus.meal:
        _totalMealTime += timeSpent;
        break;
      case JourneyStatus.waiting:
        _totalWaitingTime += timeSpent;
        break;
      case JourneyStatus.resting:
        _totalRestingTime += timeSpent;
        break;
      default:
        break;
    }
  }

  Future<void> _saveJourneyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('journeyStarted', _isJourneyStarted);

      if (_journeyStartTime != null) {
        await prefs.setInt(
          'journeyStartTime',
          _journeyStartTime!.millisecondsSinceEpoch,
        );
      }

      if (_currentActivityStartTime != null) {
        await prefs.setInt(
          'currentActivityStartTime',
          _currentActivityStartTime!.millisecondsSinceEpoch,
        );
      }

      await prefs.setInt('totalDrivingTime', _totalDrivingTime);
      await prefs.setInt('totalMealTime', _totalMealTime);
      await prefs.setInt('totalWaitingTime', _totalWaitingTime);
      await prefs.setInt('totalRestingTime', _totalRestingTime);

      await prefs.setString('journeyState', jsonEncode(_journeyState.toJson()));
    } catch (e) {
      debugPrint('Erro ao salvar dados da jornada: $e');
    }
  }

  Future<void> _clearJourneyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('journeyStarted');
      await prefs.remove('journeyStartTime');
      await prefs.remove('currentActivityStartTime');
      await prefs.remove('totalDrivingTime');
      await prefs.remove('totalMealTime');
      await prefs.remove('totalWaitingTime');
      await prefs.remove('totalRestingTime');
      await prefs.remove('journeyState');
    } catch (e) {
      debugPrint('Erro ao limpar dados da jornada: $e');
    }
  }

  Future<void> _saveToApi(int tipo, String tipoEvento) async {
    try {
      await _initLocationService(); // Atualizar localização

      // Use mock API se disponível
      if (MockApiService.isUsingMockData) {
        await MockApiService.changeJourneyStatus(
          journeyId: DateTime.now().millisecondsSinceEpoch,
          status: tipoEvento,
          latitude: _currentLocation?.latitude ?? -23.5505,
          longitude: _currentLocation?.longitude ?? -46.6333,
        );
      } else {
        await ApiService.saveJourneyEvent(
          tipo: tipo,
          tipoEvento: tipoEvento,
          latitude: _currentLocation?.latitude,
          longitude: _currentLocation?.longitude,
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar no servidor: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // Atualiza a UI a cada segundo
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
