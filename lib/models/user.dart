class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
  });

  // Factory constructor para criar uma instância de User a partir de um JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Nome não encontrado',
      email: json['email'] ?? 'Email não encontrado',
      phoneNumber: json['phone_number'] ?? 'Telefone não encontrado',
    );
  }
}
