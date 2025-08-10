class FoodSuggestion {
  final String name;
  final String quantity;
  final String reason;

  FoodSuggestion({
    required this.name,
    required this.quantity,
    required this.reason,
  });

  factory FoodSuggestion.fromJson(Map<String, dynamic> json) {
    return FoodSuggestion(
      name: json['name'] ?? 'N/A',
      quantity: json['quantity'] ?? 'N/A',
      reason: json['reason'] ?? 'Sem justificativa.',
    );
  }
}
