class GovernmentScheme {
  final String name;
  final String url;
  final String description;

  GovernmentScheme({
    required this.name,
    required this.url,
    required this.description,
  });

  factory GovernmentScheme.fromJson(Map<String, dynamic> json) {
    return GovernmentScheme(
      name: json['name'] as String,
      url: json['url'] as String,
      description: json['description'] as String,
    );
  }
}
