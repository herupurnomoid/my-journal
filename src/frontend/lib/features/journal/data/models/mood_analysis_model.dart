class MoodAnalysisModel {
  final String primaryMood;
  final int stressLevel;
  final int happinessLevel;
  final String emotionSummary;
  final List<String> recommendations;

  MoodAnalysisModel({
    required this.primaryMood,
    required this.stressLevel,
    required this.happinessLevel,
    required this.emotionSummary,
    required this.recommendations,
  });

  factory MoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    return MoodAnalysisModel(
      primaryMood: json['primaryMood'] as String? ?? 'Neutral',
      stressLevel: json['stressLevel'] as int? ?? 0,
      happinessLevel: json['happinessLevel'] as int? ?? 50,
      emotionSummary: json['emotionSummary'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
