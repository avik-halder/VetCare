// // lib/screens/home_screen.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
//
// import '../widgets/live_stream.dart';
// import 'history_screen.dart';
// import '../data/disease_suggestions.dart'; // multi-disease suggestions
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _tabIndex = 0;
//
//   // ---- Backend endpoints ----
//   final String streamUrl  = 'http://10.126.58.60:8000/video_feed';
//   final String predictApi = 'http://10.126.58.60:8000/predict-latest';
//   final String skinApi    = 'http://10.126.58.60:8000/skin-latest';
//
//   // ---- Data state ----
//   String skinPrediction = 'Loading…';
//   String internalPrediction = 'Loading…';
//   bool _loadingSkin = false;
//   bool _loadingInternal = false;
//
//   // ---- Vet call number ----
//   final String vetPhoneNumber = '+8801XXXXXXXXX'; // replace with a real number
//
//   @override
//   void initState() {
//     super.initState();
//     _refreshAll();
//   }
//
//   Future<void> _refreshAll() async {
//     await Future.wait([
//       _fetchSkinPrediction(),
//       _fetchInternalPrediction(),
//     ]);
//   }
//
//   Future<void> _fetchSkinPrediction() async {
//     setState(() => _loadingSkin = true);
//     try {
//       final res = await http.get(Uri.parse(skinApi));
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         setState(() => skinPrediction = (data['result'] ?? 'Unknown').toString());
//       } else {
//         setState(() => skinPrediction = 'Failed to load (${res.statusCode})');
//       }
//     } catch (_) {
//       setState(() => skinPrediction = 'Error');
//     } finally {
//       setState(() => _loadingSkin = false);
//     }
//   }
//
//   Future<void> _fetchInternalPrediction() async {
//     setState(() => _loadingInternal = true);
//     try {
//       final res = await http.get(Uri.parse(predictApi));
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         setState(() => internalPrediction = (data['prediction'] ?? 'Unknown').toString());
//       } else {
//         setState(() => internalPrediction = 'Failed to load (${res.statusCode})');
//       }
//     } catch (_) {
//       setState(() => internalPrediction = 'Error');
//     } finally {
//       setState(() => _loadingInternal = false);
//     }
//   }
//
//   // ---- Actions ----
//   Future<void> _openVetsInMaps() async {
//     final geoUri = Uri.parse('geo:0,0?q=veterinary+clinic');
//     final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=veterinary+clinic+near+me');
//     if (await canLaunchUrl(geoUri)) {
//       await launchUrl(geoUri);
//     } else {
//       await launchUrl(webUri, mode: LaunchMode.externalApplication);
//     }
//   }
//
//   Future<void> _callVeterinaryDoctor() async {
//     final tel = Uri.parse('tel:$vetPhoneNumber');
//     if (await canLaunchUrl(tel)) {
//       await launchUrl(tel);
//     } else {
//       _snack('Could not open dialer');
//     }
//   }
//
//   void _snack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
//
//   // ---- Suggestion Cards (0, 1, or 2) with a small gap between them ----
//   List<Widget> _suggestionCards() {
//     final advices = diseaseAdvicesFromPredictions(internalPrediction, skinPrediction);
//     if (advices.isEmpty) return const [];
//
//     return advices.asMap().entries.map((entry) {
//       final index = entry.key;
//       final advice = entry.value;
//
//       return Padding(
//         padding: EdgeInsets.only(bottom: index == advices.length - 1 ? 0 : 12), // gap between cards
//         child: _card(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header row
//                 Row(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF2E7D32).withOpacity(0.15),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       padding: const EdgeInsets.all(6),
//                       child: const Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 18),
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Suggestions',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
//                     ),
//                     const Spacer(),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFEF6C00).withOpacity(0.14),
//                         borderRadius: BorderRadius.circular(999),
//                         border: Border.all(color: const Color(0xFFEF6C00).withOpacity(0.3)),
//                       ),
//                       child: Text(
//                         advice.disease,
//                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF6C00)),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 // Tips
//                 ...advice.tips.map((t) => Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Padding(
//                         padding: EdgeInsets.only(top: 4),
//                         child: Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           t,
//                           style: const TextStyle(fontSize: 14, height: 1.3),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )),
//               ],
//             ),
//           ),
//         ),
//       );
//     }).toList();
//   }
//
//   // ---- UI ----
//   @override
//   Widget build(BuildContext context) {
//     final Color darkGreen = Colors.green[800]!;
//     final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));
//
//     // Dark status bar with white icons
//     SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
//       statusBarColor: darkGreen,
//       statusBarIconBrightness: Brightness.light,
//       statusBarBrightness: Brightness.dark,
//     ));
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: darkGreen,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: const Text(
//           '🐄 Cattle Health Monitor',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Refresh',
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _refreshAll,
//           ),
//         ],
//       ),
//
//       // --- Body with full-page gradient background ---
//       body: _tabIndex == 0
//           ? Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment(-0.9, -1),
//             end: Alignment(1, 1),
//             colors: [
//               Color(0xFFECF8ED),
//               Color(0xFFD7F4DE),
//               Color(0xFFC2EFD0),
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             // Top: scrollable content
//             Expanded(
//               child: RefreshIndicator(
//                 onRefresh: _refreshAll,
//                 child: SingleChildScrollView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionTitle('Live stream', icon: Icons.videocam_outlined, color: cs.primary),
//                       const SizedBox(height: 8),
//                       _card(
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: LiveStream(streamUrl: streamUrl),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       _sectionTitle('Status overview', icon: Icons.analytics_outlined, color: cs.primary),
//                       const SizedBox(height: 8),
//
//                       // Two status cards (stack vertically on narrow)
//                       LayoutBuilder(
//                         builder: (context, constraints) {
//                           final isNarrow = constraints.maxWidth < 520;
//                           final skinVal = _loadingSkin ? 'Loading…' : skinPrediction;
//                           final healthVal = _loadingInternal ? 'Loading…' : internalPrediction;
//
//                           // Decide if each status is healthy or disease
//                           bool isHealthy(String v) {
//                             final t = v.toLowerCase();
//                             // healthy when contains 'healthy' explicitly; anything else is considered disease
//                             return t.contains('healthy');
//                           }
//
//                           final Color skinAccent  = isHealthy(skinVal)    ? const Color(0xFF2E7D32) : Colors.red.shade700;
//                           final Color heartAccent = isHealthy(healthVal)  ? const Color(0xFFEF6C00) : Colors.red.shade700;
//
//                           final statusCards = [
//                             _statusCard(
//                               title: 'Skin status',
//                               value: skinVal,
//                               icon: Icons.pets_outlined,
//                               accent: skinAccent,
//                             ),
//                             const SizedBox(height: 12),
//                             _statusCard(
//                               title: 'Health status',
//                               value: healthVal,
//                               icon: Icons.favorite_outline,
//                               accent: heartAccent,
//                             ),
//                           ];
//
//                           if (isNarrow) {
//                             return Column(children: statusCards);
//                           }
//                           return Row(
//                             children: [
//                               Expanded(child: statusCards[0]),
//                               const SizedBox(width: 12),
//                               Expanded(child: statusCards[2]),
//                             ],
//                           );
//                         },
//                       ),
//
//                       const SizedBox(height: 14),
//
//                       // ===== Suggestion Boxes (0, 1, or 2) =====
//                       ..._suggestionCards(),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//
//             // Bottom: action buttons fixed at the very bottom
//             SafeArea(
//               top: false,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: _bottomButton(
//                         label: 'Vet clinic near me',
//                         icon: Icons.local_hospital,
//                         colors: [cs.primary, cs.primary.withOpacity(0.8)],
//                         onTap: _openVetsInMaps,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: _bottomButton(
//                         label: 'Call vet doctor',
//                         icon: Icons.call,
//                         colors: [const Color(0xFFEF6C00), const Color(0xFFE65100)],
//                         onTap: _callVeterinaryDoctor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       )
//           : _tabIndex == 1
//           ? Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: HistoryScreen(),
//       )
//           : Center(
//         child: _card(
//           child: const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text('Settings will appear here'),
//           ),
//         ),
//       ),
//
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _tabIndex,
//         onTap: (i) => setState(() => _tabIndex = i),
//         selectedItemColor: cs.primary,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//       ),
//     );
//   }
//
//   // ---- UI helpers ----
//   static Widget _card({required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.95),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.7)),
//         boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10))],
//       ),
//       child: child,
//     );
//   }
//
//   Widget _statusCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color accent,
//   }) {
//     final ok = !(value.toLowerCase().contains('error') || value.toLowerCase().contains('fail'));
//     return _card(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: accent.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: accent, size: 28),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 6),
//                   Text(
//                     value,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w800,
//                       color: ok ? Colors.black87 : Colors.red.shade700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(Icons.chevron_right_rounded, color: Colors.black26),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _bottomButton({
//     required String label,
//     required IconData icon,
//     required List<Color> colors,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: onTap,
//       child: Container(
//         height: 52,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(colors: colors),
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [BoxShadow(color: colors.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 6))],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white),
//             const SizedBox(width: 8),
//             Flexible(
//               child: Text(
//                 label,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionTitle(String text, {IconData? icon, Color? color}) {
//     return Row(
//       children: [
//         if (icon != null)
//           Container(
//             decoration: BoxDecoration(
//               color: (color ?? Colors.black87).withOpacity(0.12),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             padding: const EdgeInsets.all(6),
//             child: Icon(icon, size: 16, color: color ?? Colors.black87),
//           ),
//         if (icon != null) const SizedBox(width: 8),
//         Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
//       ],
//     );
//   }
// }




// lib/screens/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../widgets/live_stream.dart';
import 'history_screen.dart';
import '../data/disease_suggestions.dart'; // multi-disease suggestions

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  // ---- Backend endpoints ----
  final String streamUrl  = 'http://10.126.58.60:8000/video_feed';
  final String predictApi = 'http://10.126.58.60:8000/predict-latest';
  final String skinApi    = 'http://10.126.58.60:8000/skin-latest';

  // ---- Data state ----
  String skinPrediction = 'Loading…';
  String internalPrediction = 'Loading…';
  bool _loadingSkin = false;
  bool _loadingInternal = false;

  // ---- Vet call number ----
  final String vetPhoneNumber = '+8801XXXXXXXXX'; // replace with a real number

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchSkinPrediction(),
      _fetchInternalPrediction(),
    ]);
  }

  Future<void> _fetchSkinPrediction() async {
    setState(() => _loadingSkin = true);
    try {
      final res = await http.get(Uri.parse(skinApi));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => skinPrediction = (data['result'] ?? 'Unknown').toString());
      } else {
        setState(() => skinPrediction = 'Failed to load (${res.statusCode})');
      }
    } catch (_) {
      setState(() => skinPrediction = 'Error');
    } finally {
      setState(() => _loadingSkin = false);
    }
  }

  Future<void> _fetchInternalPrediction() async {
    setState(() => _loadingInternal = true);
    try {
      final res = await http.get(Uri.parse(predictApi));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => internalPrediction = (data['prediction'] ?? 'Unknown').toString());
      } else {
        setState(() => internalPrediction = 'Failed to load (${res.statusCode})');
      }
    } catch (_) {
      setState(() => internalPrediction = 'Error');
    } finally {
      setState(() => _loadingInternal = false);
    }
  }

  // ===================== NEW: Tap actions for XAI sheets =====================

  Future<void> _openSkinStatus() async {
    // loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await http.get(Uri.parse(skinApi));
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader

      if (res.statusCode != 200) {
        _snack('Failed to load skin status (${res.statusCode})');
        return;
      }
      final Map<String, dynamic> data = json.decode(res.body);
      // await _showSkinSheet(data);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _snack('Failed to load skin status: $e');
      }
    }
  }

  Future<void> _openHealthExplanation() async {
    // loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final uri = Uri.parse('$predictApi?explain=true&k=3');
      final res = await http.get(uri);
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader

      if (res.statusCode != 200) {
        _snack('Failed to load health explanation (${res.statusCode})');
        return;
      }
      final Map<String, dynamic> data = json.decode(res.body);

      // Optionally reflect predicted class on the card subtitle
      final pred = (data['prediction'] ?? '').toString();
      if (pred.isNotEmpty) {
        setState(() => internalPrediction = pred);
      }

      await _showHealthSheet(data);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _snack('Failed to load health explanation: $e');
      }
    }
  }

  // ---------------------- Bottom sheet builders ----------------------

  // Future<void> _showSkinSheet(Map<String, dynamic> data) async {
  //   final result = (data['result'] ?? 'Unknown').toString();
  //   final ts = (data['timestamp'] ?? '').toString();
  //
  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     showDragHandle: true,
  //     builder: (_) => SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('Skin status', style: Theme.of(context).textTheme.titleLarge),
  //             const SizedBox(height: 8),
  //             Row(
  //               children: [
  //                 Icon(
  //                   result.toLowerCase().contains('lumpy') ? Icons.warning_amber : Icons.check_circle,
  //                   color: result.toLowerCase().contains('lumpy') ? Colors.orange : Colors.green,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(result, style: Theme.of(context).textTheme.titleMedium),
  //               ],
  //             ),
  //             const SizedBox(height: 8),
  //             Text(ts.isEmpty ? 'No timestamp' : 'Last updated: $ts'),
  //             const SizedBox(height: 12),
  //             const Text(
  //               'This result comes from the lumpy-skin image classifier on the most recent frame. '
  //                   'For feature‑level reasons (like temperature/pulse), open the Health card — that uses SHAP on the sensor model.',
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // REPLACE your existing _showHealthSheet with this:
  Future<void> _showHealthSheet(Map<String, dynamic> data) async {
    final pred = (data['prediction'] ?? '').toString();
    final sentence = (data['top_features_sentence'] ?? '').toString();
    final List topAll = (data['top_features'] ?? []) as List;
    final List top = topAll.take(3).toList(); // NEW: limit to top 3
    final Map probs = (data['probabilities'] ?? {}) as Map;


    // Prepare numbers
    final shapValues = top
        .map<double>((t) => (Map<String, dynamic>.from(t)['shap'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final maxAbsShap = shapValues.fold<double>(0.0, (m, v) => v.abs() > m ? v.abs() : m);
    final sortedProbs = probs.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== Header =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.monitor_heart, color: Colors.white.withOpacity(0.95)),
                              const SizedBox(width: 8),
                              Text('Health explanation',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _pill(pred.isEmpty ? 'Unknown' : pred, color: Colors.white, textColor: const Color(0xFF1B5E20)),
                              _pill('Top features via SHAP', color: Colors.white24, textColor: Colors.white),
                            ],
                          ),
                          if (sentence.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              sentence,
                              style: const TextStyle(color: Colors.white, height: 1.25),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ===== Body =====
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top features
                            Row(
                              children: [
                                const Icon(Icons.bolt, size: 18, color: Color(0xFF1B5E20)),
                                const SizedBox(width: 6),
                                Text('Top contributing features',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (top.isEmpty)
                              _ghostCard(const Text('No SHAP features available.'))
                            else
                              ...top.map((t) {
                                final m = Map<String, dynamic>.from(t as Map);
                                final name = (m['display'] ?? m['feature']).toString();
                                final hint = (m['hint'] ?? '').toString();
                                final shap = (m['shap'] as num?)?.toDouble() ?? 0.0;
                                final strength = (maxAbsShap > 0)
                                    ? (shap.abs() / maxAbsShap).clamp(0.0, 1.0)
                                    : 0.0;

                                return _featureCard(
                                  icon: Icons.analytics_outlined,
                                  title: name,
                                  badge: hint,
                                  badgeColor: _hintColor(hint),
                                  barValue: strength,
                                  barColor: _shapColor(shap),
                                );
                              }),


                            const SizedBox(height: 16),

                            // Class probabilities
                            Row(
                              children: [
                                const Icon(Icons.equalizer, size: 18, color: Color(0xFF1B5E20)),
                                const SizedBox(width: 6),
                                Text('Class probabilities',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (sortedProbs.isEmpty)
                              _ghostCard(const Text('No probability data available.'))
                            else
                              ...sortedProbs.map((e) {
                                final label = e.key.toString();
                                final p = (e.value as num).toDouble();
                                return _probRow(label: label, value: p);
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
// Small white pill chip
  Widget _pill(String text, {Color color = const Color(0xFFE8F5E9), Color textColor = const Color(0xFF1B5E20)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
    );
  }

// Neutral card for empty states
  Widget _ghostCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EFE5)),
      ),
      child: child,
    );
  }

// One feature row with badge and SHAP strength bar
  Widget _featureCard({
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
    required double barValue, // 0..1
    required Color barColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECE8)),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: barColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Text(
                  badge.isEmpty ? '—' : badge,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: barValue,
              backgroundColor: const Color(0xFFEAEFF0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }


// Probability row with bar
  Widget _probRow({required String label, required double value}) {
    final pct = (value * 100).clamp(0, 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text('${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value.clamp(0, 1),
              backgroundColor: const Color(0xFFF0F2F1),
              valueColor: AlwaysStoppedAnimation<Color>(_probColor(value)),
            ),
          ),
        ],
      ),
    );
  }

// Colors
  Color _hintColor(String hint) {
    final h = hint.toLowerCase();
    if (h.contains('high')) return const Color(0xFFD84315);     // orange-red
    if (h.contains('low')) return const Color(0xFF1565C0);      // blue
    if (h.contains('normal')) return const Color(0xFF2E7D32);   // green
    return const Color(0xFF546E7A);                              // slate
  }

  Color _shapColor(double shap) {
    // Positive contribution → green; negative → red
    return shap >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
  }

  Color _probColor(double v) {
    // Gradient-ish mapping by value
    if (v >= 0.75) return const Color(0xFF2E7D32);
    if (v >= 0.5)  return const Color(0xFF43A047);
    if (v >= 0.25) return const Color(0xFF66BB6A);
    return const Color(0xFFA5D6A7);
  }


  // =====================================================================

  // ---- Actions ----
  Future<void> _openVetsInMaps() async {
    final geoUri = Uri.parse('geo:0,0?q=veterinary+clinic');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=veterinary+clinic+near+me');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callVeterinaryDoctor() async {
    final tel = Uri.parse('tel:$vetPhoneNumber');
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    } else {
      _snack('Could not open dialer');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ---- Suggestion Cards (0, 1, or 2) with a small gap between them ----
  List<Widget> _suggestionCards() {
    final advices = diseaseAdvicesFromPredictions(internalPrediction, skinPrediction);
    if (advices.isEmpty) return const [];

    return advices.asMap().entries.map((entry) {
      final index = entry.key;
      final advice = entry.value;

      return Padding(
        padding: EdgeInsets.only(bottom: index == advices.length - 1 ? 0 : 12), // gap between cards
        child: _card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Suggestions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF6C00).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFEF6C00).withOpacity(0.3)),
                      ),
                      child: Text(
                        advice.disease,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF6C00)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tips
                ...advice.tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t,
                          style: const TextStyle(fontSize: 14, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final Color darkGreen = Colors.green[800]!;
    final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));

    // Dark status bar with white icons
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: darkGreen,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '🐄 Cattle Health Monitor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshAll,
          ),
        ],
      ),

      // --- Body with full-page gradient background ---
      body: _tabIndex == 0
          ? Container(
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
        child: Column(
          children: [
            // Top: scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Live stream', icon: Icons.videocam_outlined, color: cs.primary),
                      const SizedBox(height: 8),
                      _card(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LiveStream(streamUrl: streamUrl),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Status overview', icon: Icons.analytics_outlined, color: cs.primary),
                      const SizedBox(height: 8),

                      // Two status cards (stack vertically on narrow)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 520;
                          final skinVal = _loadingSkin ? 'Loading…' : skinPrediction;
                          final healthVal = _loadingInternal ? 'Loading…' : internalPrediction;

                          // Decide if each status is healthy or disease
                          bool isHealthy(String v) {
                            final t = v.toLowerCase();
                            // healthy when contains 'healthy' explicitly; anything else is considered disease
                            return t.contains('healthy');
                          }

                          final Color skinAccent  = isHealthy(skinVal)   ? const Color(0xFF2E7D32) : Colors.red.shade700;
                          final Color heartAccent = isHealthy(healthVal) ? const Color(0xFFEF6C00) : Colors.red.shade700;

                          final statusCards = [
                            _statusCard(
                              title: 'Skin status',
                              value: skinVal,
                              icon: Icons.pets_outlined,
                              accent: skinAccent,
                              onTap: _openSkinStatus, // NEW
                            ),
                            const SizedBox(height: 12),
                            _statusCard(
                              title: 'Health status',
                              value: healthVal,
                              icon: Icons.favorite_outline,
                              accent: heartAccent,
                              onTap: _openHealthExplanation, // NEW
                            ),
                          ];

                          if (isNarrow) {
                            return Column(children: statusCards);
                          }
                          return Row(
                            children: [
                              Expanded(child: statusCards[0]),
                              const SizedBox(width: 12),
                              Expanded(child: statusCards[2]),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // ===== Suggestion Boxes (0, 1, or 2) =====
                      ..._suggestionCards(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom: action buttons fixed at the very bottom
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _bottomButton(
                        label: 'Vet clinic near me',
                        icon: Icons.local_hospital,
                        colors: [cs.primary, cs.primary.withOpacity(0.8)],
                        onTap: _openVetsInMaps,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _bottomButton(
                        label: 'Call vet doctor',
                        icon: Icons.call,
                        colors: [const Color(0xFFEF6C00), const Color(0xFFE65100)],
                        onTap: _callVeterinaryDoctor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
          : _tabIndex == 1
          ? const Padding(
        padding: EdgeInsets.all(8.0),
        child: HistoryScreen(),
      )
          : Center(
        child: _card(
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Settings will appear here'),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        selectedItemColor: cs.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // ---- UI helpers ----
  static Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: child,
    );
  }

  Widget _statusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    VoidCallback? onTap, // NEW
  }) {
    final ok = !(value.toLowerCase().contains('error') || value.toLowerCase().contains('fail'));

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ok ? Colors.black87 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black26),
        ],
      ),
    );

    return _card(
      child: onTap == null
          ? content
          : InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }

  Widget _bottomButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: colors.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, {IconData? icon, Color? color}) {
    return Row(
      children: [
        if (icon != null)
          Container(
            decoration: BoxDecoration(
              color: (color ?? Colors.black87).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: color ?? Colors.black87),
          ),
        if (icon != null) const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
