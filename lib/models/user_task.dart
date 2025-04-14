class UserTask {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String category;
  final String disorderType;
  
  bool get isCompleted => completedAt != null;
  
  UserTask({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.completedAt,
    required this.category,
    required this.disorderType,
  });
  
  factory UserTask.fromJson(Map<String, dynamic> json) {
    return UserTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      category: json['category'],
      disorderType: json['disorder_type'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'category': category,
      'disorder_type': disorderType,
    };
  }
}