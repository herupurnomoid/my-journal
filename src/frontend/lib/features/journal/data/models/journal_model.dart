import 'package:cloud_firestore/cloud_firestore.dart';

class JournalModel {
  final String id;
  final String title;
  final String content; // Could be Rich Text/JSON later
  final String location;
  final String status; // 'Draft' or 'Published'
  final String mood; // Emoji or Icon name
  final String? imageUrl; // Cover image URL
  final DateTime createdAt;
  
  // AI Analysis Fields
  final int? stressLevel;
  final int? happinessLevel;
  final String? emotionSummary;
  final List<String>? recommendations;

  JournalModel({
    required this.id,
    required this.title,
    required this.content,
    required this.location,
    required this.status,
    required this.mood,
    this.imageUrl,
    required this.createdAt,
    this.stressLevel,
    this.happinessLevel,
    this.emotionSummary,
    this.recommendations,
  });

  factory JournalModel.fromMap(Map<String, dynamic> data, String documentId) {
    return JournalModel(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      location: data['location'] ?? '',
      status: data['status'] ?? 'Draft',
      mood: data['mood'] ?? '😊',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stressLevel: data['stressLevel'],
      happinessLevel: data['happinessLevel'],
      emotionSummary: data['emotionSummary'],
      recommendations: (data['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'location': location,
      'status': status,
      'mood': mood,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (stressLevel != null) 'stressLevel': stressLevel,
      if (happinessLevel != null) 'happinessLevel': happinessLevel,
      if (emotionSummary != null) 'emotionSummary': emotionSummary,
      if (recommendations != null) 'recommendations': recommendations,
    };
  }

  String get moodEmoji {
    if (mood.runes.length <= 2 && !mood.contains(RegExp(r'[a-zA-Z]'))) return mood;
    final m = mood.toLowerCase();
    
    if (m.contains('happy') || m.contains('bahagia') || m.contains('senang') || m.contains('gembira')) return '😊';
    if (m.contains('sad') || m.contains('sedih') || m.contains('kecewa')) return '😢';
    if (m.contains('angry') || m.contains('marah') || m.contains('kesal')) return '😠';
    if (m.contains('anxious') || m.contains('cemas') || m.contains('khawatir') || m.contains('gugup')) return '😰';
    if (m.contains('neutral') || m.contains('netral') || m.contains('biasa')) return '😐';
    if (m.contains('excited') || m.contains('semangat') || m.contains('antusias')) return '🤩';
    if (m.contains('tired') || m.contains('lelah') || m.contains('capek')) return '😴';
    if (m.contains('calm') || m.contains('tenang') || m.contains('damai')) return '😌';
    if (m.contains('stress') || m.contains('stres') || m.contains('tegang')) return '😫';
    
    return '😎';
  }
}

