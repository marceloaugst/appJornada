class Vehicle {
  final int? id;
  final String? plate;
  final String? model;
  final int? companyId;

  Vehicle({this.id, this.plate, this.model, this.companyId});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? json['id_veiculo'],
      plate: json['plate']?.toString() ?? json['placa']?.toString(),
      model: json['model']?.toString() ?? json['modelo']?.toString(),
      companyId: json['companyId'] ?? json['company_id'] ?? json['empresa_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'model': model,
      'companyId': companyId,
      // Manter compatibilidade com API original
      'id_veiculo': id,
      'placa': plate,
      'modelo': model,
    };
  }
}
