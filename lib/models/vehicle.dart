class Vehicle {
  final int? id;
  final String? plate;
  final String? model;
  final int? companyId;
  final int? driverId; // ID do motorista vinculado ao veículo

  Vehicle({this.id, this.plate, this.model, this.companyId, this.driverId});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    print('DEBUG Vehicle.fromJson recebeu: $json');

    final id = json['id'] ?? json['id_veiculo'];
    final plate =
        json['plate']?.toString() ??
        json['placa']?.toString() ??
        json['key']?.toString() ??
        json['value']?.toString();
    final model = json['model']?.toString() ?? json['modelo']?.toString();
    final companyId =
        json['companyId'] ?? json['company_id'] ?? json['empresa_id'];
    final driverId =
        json['driverId'] ?? json['driver_id'] ?? json['id_pessoal'];

    print(
      'DEBUG Vehicle valores: id=$id, plate=$plate, model=$model, companyId=$companyId, driverId=$driverId',
    );

    final vehicle = Vehicle(
      id: id,
      plate: plate,
      model: model,
      companyId: companyId,
      driverId: driverId,
    );

    print(
      'DEBUG Vehicle criado: id=${vehicle.id}, plate=${vehicle.plate}, driverId=${vehicle.driverId}',
    );
    return vehicle;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'model': model,
      'companyId': companyId,
      'driverId': driverId,
      // Manter compatibilidade com API original
      'id_veiculo': id,
      'placa': plate,
      'modelo': model,
      'id_pessoal': driverId,
    };
  }
}
