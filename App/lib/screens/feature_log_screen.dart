import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeatureLogScreen extends StatefulWidget {
  final String title;
  final String featureKey; // e.g., 'Temp', 'Pulse'
  final String unit;       // display unit
  final List<Map<String, dynamic>> logs; // raw docs from /sensor-latest
  final Color accent;
  final IconData icon;

  const FeatureLogScreen({
    super.key,
    required this.title,
    required this.featureKey,
    required this.unit,
    required this.logs,
    required this.accent,
    required this.icon,
  });

  @override
  State<FeatureLogScreen> createState() => _FeatureLogScreenState();
}

class _FeatureLogScreenState extends State<FeatureLogScreen> {
  late final List<_RowData> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _extractRows();
  }

  List<_RowData> _extractRows() {
    final f = widget.featureKey;
    final fmt = DateFormat('MMM d, h:mm a');

    return widget.logs.map<_RowData>((doc) {
      final ts = DateTime.tryParse(doc['timestamp'] ?? '');
      final displayTime = ts != null ? fmt.format(ts) : (doc['timestamp'] ?? '');
      final raw = doc[f];
      String value;
      if (raw == null) {
        value = '—';
      } else if (raw is num) {
        value = raw.toStringAsFixed(2);
      } else {
        value = raw.toString();
      }
      return _RowData(time: displayTime, value: value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chipBg = widget.accent.withOpacity(0.12);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.accent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -1),
            end: Alignment(1, 1),
            colors: [
              Color(0xFFECF8ED),
              Color(0xFFD7F4DE),
              Color(0xFFC2EFD0),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Header card
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.7)),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10))
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(widget.icon, color: widget.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: widget.accent.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Latest: ${_rows.isNotEmpty ? _rows.first.value + widget.unit : '—'}',
                      style: TextStyle(color: widget.accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Data table
            _buildTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Value')),
          ],
          rows: _rows
              .map(
                (r) => DataRow(
              cells: [
                DataCell(Text(r.time)),
                DataCell(Text(r.value + widget.unit)),
              ],
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

class _RowData {
  final String time;
  final String value;
  _RowData({required this.time, required this.value});
}
