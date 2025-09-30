enum JourneyStatus { notStarted, driving, meal, waiting, resting, ended }

class JourneyState {
  final bool encerrar;
  final bool direcao;
  final bool refeicao;
  final bool espera;
  final bool descansar;

  JourneyState({
    this.encerrar = false,
    this.direcao = false,
    this.refeicao = false,
    this.espera = false,
    this.descansar = false,
  });

  factory JourneyState.fromJson(Map<String, dynamic> json) {
    return JourneyState(
      encerrar: json['encerrar'] ?? false,
      direcao: json['direcao'] ?? false,
      refeicao: json['refeicao'] ?? false,
      espera: json['espera'] ?? false,
      descansar: json['descansar'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encerrar': encerrar,
      'direcao': direcao,
      'refeicao': refeicao,
      'espera': espera,
      'descansar': descansar,
    };
  }

  JourneyState copyWith({
    bool? encerrar,
    bool? direcao,
    bool? refeicao,
    bool? espera,
    bool? descansar,
  }) {
    return JourneyState(
      encerrar: encerrar ?? this.encerrar,
      direcao: direcao ?? this.direcao,
      refeicao: refeicao ?? this.refeicao,
      espera: espera ?? this.espera,
      descansar: descansar ?? this.descansar,
    );
  }

  JourneyStatus get currentStatus {
    if (encerrar) return JourneyStatus.ended;
    if (direcao) return JourneyStatus.driving;
    if (refeicao) return JourneyStatus.meal;
    if (espera) return JourneyStatus.waiting;
    if (descansar) return JourneyStatus.resting;
    return JourneyStatus.notStarted;
  }
}
