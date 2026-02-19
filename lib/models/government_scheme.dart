class GovernmentScheme {
  final String name;
  final String url;
  final String description;
  final List<String> benefits;
  final List<String> eligibility;
  final List<String> documents;
  final String process;

  GovernmentScheme({
    required this.name,
    required this.url,
    required this.description,
    required this.benefits,
    required this.eligibility,
    required this.documents,
    required this.process,
  });

  factory GovernmentScheme.fromJson(Map<String, dynamic> json) {
    return GovernmentScheme(
      name: json['name'] as String,
      url: json['url'] as String,
      description: json['description'] as String,
      benefits: List<String>.from(json['benefits'] ?? []),
      eligibility: List<String>.from(json['eligibility'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
      process: json['process'] as String? ?? '',
    );
  }
}
