// lib/screens/history_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'feature_log_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ---- Backend base & paths ----
  static const String baseUrl = 'http://10.126.58.60:8000';
  static const String sensorLatestPath = '/sensor-latest'; // returns latest ~10 sensor docs (list)
  static const String lumpyLatestPath  = '/skin-latest';   // returns {result, timestamp}
  static const String lumpyLogsPath    = '/logs';          // returns list of docs for skin predictions

  // ---- Data ----
  List<Map<String, dynamic>> _sensorLogs = []; // from /sensor-latest
  List<Map<String, dynamic>> _lumpyLogs  = []; // from /logs (normalized)
  String? _latestLumpyText; // from /skin-latest
  bool _loading = false;
  String? _error;

  // 7 feature cards (added Lumpy)
  final List<_FeatureDef> _features = const [
    _FeatureDef(key: 'Pulse',     title: 'Pulse Rate',        unit: ' bpm', color: Color(0xFFE95849), icon: Icons.favorite),
    _FeatureDef(key: 'Temp',      title: 'Temperature',       unit: '°C',   color: Color(0xFF2F80ED), icon: Icons.thermostat),
    _FeatureDef(key: 'pH',        title: 'pH Level',          unit: '',     color: Color(0xFF6A1B9A), icon: Icons.bubble_chart),
    _FeatureDef(key: 'MQ',        title: 'Methane Gas',       unit: '',     color: Color(0xFF27AE60), icon: Icons.cloud_outlined),
    _FeatureDef(key: 'Accel_Mag', title: 'Accel Mag',         unit: '',     color: Color(0xFFF2994A), icon: Icons.directions_run),
    _FeatureDef(key: 'Gyro_Mag',  title: 'Gyro Mag',          unit: '',     color: Color(0xFF00B8D9), icon: Icons.rotate_right),
    _FeatureDef(key: 'Lumpy',     title: 'Lumpy Skin Status', unit: '',     color: Color(0xFF8E44AD), icon: Icons.pets),
  ];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _fetchSensorLogs(),
        _fetchLumpyLatest(),
        _fetchLumpyLogs(),
      ]);
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---- Safe timestamp comparator: newest first ----
  int _compareByTimestampDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
    DateTime? ta = DateTime.tryParse((a['timestamp'] ?? '').toString());
    DateTime? tb = DateTime.tryParse((b['timestamp'] ?? '').toString());
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;  // nulls go last
    if (tb == null) return -1; // nulls go last
    return tb.compareTo(ta);   // newest first
  }

  Future<void> _fetchSensorLogs() async {
    final res = await http.get(Uri.parse('$baseUrl$sensorLatestPath'));
    if (res.statusCode != 200) {
      throw Exception('sensor-latest error ${res.statusCode}');
    }
    final List<dynamic> raw = json.decode(res.body);
    final parsed = raw
        .whereType<Map<String, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList()
      ..sort(_compareByTimestampDesc);

    setState(() => _sensorLogs = parsed);
  }

  Future<void> _fetchLumpyLatest() async {
    final res = await http.get(Uri.parse('$baseUrl$lumpyLatestPath'));
    if (res.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(res.body);
      if (body.containsKey('error')) {
        setState(() => _latestLumpyText = '—');
      } else {
        setState(() => _latestLumpyText = (body['result'] ?? '—').toString());
      }
    } else {
      setState(() => _latestLumpyText = '—');
    }
  }

  Future<void> _fetchLumpyLogs() async {
    final res = await http.get(Uri.parse('$baseUrl$lumpyLogsPath'));
    if (res.statusCode != 200) {
      throw Exception('logs error ${res.statusCode}');
    }
    final List<dynamic> raw = json.decode(res.body);
    // Normalize to { timestamp: "...", Lumpy: "<label>" }
    final parsed = raw
        .whereType<Map<String, dynamic>>()
        .map((m) {
      final mm = Map<String, dynamic>.from(m);
      final ts  = (mm['timestamp'] ?? '').toString();
      final res = (mm['result'] ?? '').toString();
      return {
        'timestamp': ts,
        'Lumpy': res,
      };
    })
        .toList()
      ..sort(_compareByTimestampDesc);

    setState(() => _lumpyLogs = parsed);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _sensorLogs.isEmpty && _lumpyLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _sensorLogs.isEmpty && _lumpyLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // two columns
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _features.length,
        itemBuilder: (context, i) {
          final f = _features[i];

          // Card value: sensor features pull from _sensorLogs; Lumpy pulls from _latestLumpyText
          final valueText = f.key == 'Lumpy'
              ? (_latestLumpyText ?? '—')
              : (_latestForSensor(f.key) ?? '—');

          return _FeatureCard(
            def: f,
            valueText: valueText,
            onTap: () {
              if (f.key == 'Lumpy') {
                // Lumpy table
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeatureLogScreen(
                      title: f.title,
                      featureKey: f.key, // "Lumpy"
                      unit: f.unit,
                      logs: _lumpyLogs,   // already normalized
                      accent: f.color,
                      icon: f.icon,
                    ),
                  ),
                );
              } else {
                // Sensor table
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeatureLogScreen(
                      title: f.title,
                      featureKey: f.key, // e.g. "Temp"
                      unit: f.unit,
                      logs: _sensorLogs,
                      accent: f.color,
                      icon: f.icon,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  String? _latestForSensor(String key) {
    if (_sensorLogs.isEmpty) return null;
    final v = _sensorLogs.first[key];
    if (v == null) return null;
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }
}

class _FeatureDef {
  final String key;
  final String title;
  final String unit;
  final Color color;
  final IconData icon;
  const _FeatureDef({
    required this.key,
    required this.title,
    required this.unit,
    required this.color,
    required this.icon,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureDef def;
  final String valueText;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.def,
    required this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = def.color.withOpacity(0.10);
    final border = def.color;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(def.icon, color: Colors.black54),
            const Spacer(),
            Text(
              def.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: valueText,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: def.unit,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
