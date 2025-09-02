class FeatureFlags {
  final bool workoutEnabled;
  final bool photoEstimatorEnabled;

  FeatureFlags({
    required this.workoutEnabled,
    required this.photoEstimatorEnabled,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return FeatureFlags(
      workoutEnabled: data['workout_module_enabled'] == true,
      photoEstimatorEnabled: data['photo_estimator_enabled'] == true,
    );
  }

  static FeatureFlags defaults() => FeatureFlags(
        workoutEnabled: false,
        photoEstimatorEnabled: true,
      );
}
