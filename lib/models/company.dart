class Company {
  final int? id;
  final String? name;
  final String? code;
  final String key; // Para compatibilidade com API original
  final String value; // Para compatibilidade com API original

  Company({
    this.id,
    this.name,
    this.code,
    required this.key,
    required this.value,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name']?.toString(),
      code: json['code']?.toString(),
      key: json['key']?.toString() ?? json['code']?.toString() ?? '',
      value: json['value']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code, 'key': key, 'value': value};
  }
}
