import 'package:flutter/material.dart';

class PredictionBoxes extends StatelessWidget {
  final String skinPrediction;
  final String internalPrediction;

  const PredictionBoxes({
    required this.skinPrediction,
    required this.internalPrediction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBox('🐄 Skin Status', skinPrediction, Colors.orange),
        SizedBox(height: 10),
        _buildBox('🧪 Internal Disease', internalPrediction, Colors.blue),
      ],
    );
  }

  Widget _buildBox(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 18, color: Colors.black87)),
        ],
      ),
    );
  }
}
