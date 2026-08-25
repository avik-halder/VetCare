class SensorData {
  final String timestamp;
  final double? temp, mq, pulse, accelMag, gyroMag, ph;

  SensorData({
    required this.timestamp,
    this.temp,
    this.mq,
    this.pulse,
    this.accelMag,
    this.gyroMag,
    this.ph,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: json['timestamp'],
      temp: (json['Temp'] ?? 0).toDouble(),
      mq: (json['MQ'] ?? 0).toDouble(),
      pulse: (json['Pulse'] ?? 0).toDouble(),
      accelMag: (json['Accel_Mag'] ?? 0).toDouble(),
      gyroMag: (json['Gyro_Mag'] ?? 0).toDouble(),
      ph: (json['pH'] ?? 0).toDouble(),
    );
  }

  double? getFieldValue(String field) {
    switch (field) {
      case 'Temp': return temp;
      case 'MQ': return mq;
      case 'Pulse': return pulse;
      case 'Accel_Mag': return accelMag;
      case 'Gyro_Mag': return gyroMag;
      case 'pH': return ph;
      default: return null;
    }
  }
}
