class User {
  final int? id;
  final String? name;
  final String? cpf;
  final String? matricula;
  final String? database;
  final int? companyId;

  User({
    this.id,
    this.name,
    this.cpf,
    this.matricula,
    this.database,
    this.companyId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['id_pessoal'],
      name: json['name']?.toString() ?? json['nome']?.toString(),
      cpf: json['cpf']?.toString(),
      matricula: json['matricula']?.toString(),
      database: json['database']?.toString(),
      companyId: json['companyId'] ?? json['company_id'] ?? json['empresa_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      'matricula': matricula,
      'database': database,
      'companyId': companyId,
      // Manter compatibilidade com API original
      'id_pessoal': id,
      'nome': name,
    };
  }
}
