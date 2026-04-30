enum ClassMaterialType { pdf, link, video }
enum MaterialCategory { material, homework }

class ClassMaterial {
  final String id;
  final String title;
  final String? description;
  final ClassMaterialType type;
  final MaterialCategory category;
  final String url;
  final DateTime createdAt;
  final bool isCompleted;

  ClassMaterial({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.category,
    required this.url,
    required this.createdAt,
    this.isCompleted = false,
  });

  factory ClassMaterial.fromJson(Map<String, dynamic> json) {
    ClassMaterialType type;
    switch (json['type']) {
      case 'PDF':
        type = ClassMaterialType.pdf;
        break;
      case 'VIDEO':
        type = ClassMaterialType.video;
        break;
      default:
        type = ClassMaterialType.link;
    }

    MaterialCategory category;
    switch (json['category']) {
      case 'HOMEWORK':
        category = MaterialCategory.homework;
        break;
      default:
        category = MaterialCategory.material;
    }

    return ClassMaterial(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: type,
      category: category,
      url: json['url'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
