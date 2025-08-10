class Food {
  final String name;
  final String quantity;

  Food({required this.name, required this.quantity});

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'] ?? 'N/A',
      quantity: json['quantity'] ?? 'N/A',
    );
  }
}
