class Prediction {
  final String timestamp;
  final String result;

  Prediction({required this.timestamp, required this.result});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      timestamp: json['timestamp'] ?? '',
      result: json['result'] ?? '',
    );
  }
}
