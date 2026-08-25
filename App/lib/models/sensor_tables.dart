import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class SensorTables extends StatefulWidget {
  @override
  _SensorTablesState createState() => _SensorTablesState();
}

class _SensorTablesState extends State<SensorTables> {
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    fetchSensorData();
  }

  Future<void> fetchSensorData() async {
    final data = await ApiService.getLatestSensorData();
    setState(() {
      _data = data;
    });
  }

  Widget buildSensorTable(String title, String field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Value')),
            ],
            rows: _data.map((entry) {
              final ts = DateTime.parse(entry['timestamp']);
              final value = entry[field]?.toString() ?? '--';
              return DataRow(cells: [
                DataCell(Text(DateFormat('yyyy-MM-dd').format(ts))),
                DataCell(Text(DateFormat('HH:mm:ss').format(ts))),
                DataCell(Text(value)),
              ]);
            }).toList(),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _data.isEmpty
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            buildSensorTable("Temperature", "Temp"),
            buildSensorTable("MQ", "MQ"),
            buildSensorTable("Pulse", "Pulse"),
            buildSensorTable("Accel_Mag", "Accel_Mag"),
            buildSensorTable("Gyro_Mag", "Gyro_Mag"),
            buildSensorTable("pH", "pH"),
          ],
        ),
      ),
    );
  }
}
