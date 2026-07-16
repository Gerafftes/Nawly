class JobFindData {
  const JobFindData({
    required this.id,
    required this.title,
    required this.time,
    required this.price,
    required this.distance,
    this.showVerified = false,
  });

  factory JobFindData.fromJson(Map<String, Object?> json) {
    return JobFindData(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      price: json['price'] as String,
      distance: json['distance'] as String,
      showVerified: json['showVerified'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String time;
  final String price;
  final String distance;
  final bool showVerified;
}
