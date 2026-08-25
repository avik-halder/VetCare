// lib/data/disease_suggestions.dart

/// Model used by the UI.
class DiseaseAdvice {
  final String disease;          // Display name
  final List<String> tips;
  const DiseaseAdvice({required this.disease, required this.tips});

  bool get hasAdvice => tips.isNotEmpty;
}

/// Canonical disease -> tips  (keys are LOWERCASE canonical names)
const Map<String, List<String>> _suggestions = {
  'ketosis': [
    'Give molasses water (2–3 liters mixed in water) twice a day',
    'Give rice bran with a little oil cake',
    'Call local livestock doctor quickly',
  ],
  'blackleg': [
    'Keep animal in a dry, clean place',
    'Do not move it much',
    'Call livestock doctor fast',
    'Vaccinate other cows in the area',
  ],
  'mastitis': [
    'Wash udder with warm clean water before and after milking',
    'Milk gently every few hours',
    'Keep shed clean and free from flies',
    'Call vet for medicine',
  ],
  'ruminal bloat': [
    'Stop feeding green fodder or water hyacinth',
    'Give 200–300 ml mustard oil or 500 ml coconut oil to drink',
    'Walk animal slowly',
    'Call livestock doctor if swelling is big',
  ],
  'lumpy skin disease (lsd)': [
    'Keep the animal in a mosquito and fly-free shed',
    'Give clean water and soft feed (green grass, rice bran)',
    'Wash skin sores with clean water and mild antiseptic',
    'Avoid heavy work or moving the animal',
    'Call livestock doctor for vaccine or treatment',
  ],
};

/// Aliases (LOWERCASE) -> canonical key in [_suggestions].
/// Includes the exact API string "lumpy skin cow".
const Map<String, String> _aliases = {
  // Internal disease names & variants
  'ketosis': 'ketosis',
  'blackleg': 'blackleg',
  'mastitis': 'mastitis',
  'ruminal bloat': 'ruminal bloat',
  'bloat': 'ruminal bloat',

  // Lumpy variants (skin model or text)
  'lumpy': 'lumpy skin disease (lsd)',
  'lumpy skin': 'lumpy skin disease (lsd)',
  'lumpy skin disease': 'lumpy skin disease (lsd)',
  'lumpy skin cow': 'lumpy skin disease (lsd)', // <-- important
  'lsd': 'lumpy skin disease (lsd)',
};

String _normalize(String s) => s.trim().toLowerCase();

bool _isNeutral(String t) {
  final s = _normalize(t);
  return s.isEmpty || s == 'healthy' || s == 'unknown' || s.contains('error') || s.contains('fail');
}

/// Return ALL advices detected from the two predictions:
/// - If both internal disease and lumpy are present -> two items
/// - If one -> one item
/// - If none -> empty list
List<DiseaseAdvice> diseaseAdvicesFromPredictions(
    String internalPrediction,
    String skinPrediction,
    ) {
  final internal = _normalize(internalPrediction);
  final skin = _normalize(skinPrediction);

  // Collect unique canonical disease keys (use a set to dedupe)
  final Set<String> hits = {};

  if (!_isNeutral(internal)) {
    for (final e in _aliases.entries) {
      if (internal.contains(e.key)) hits.add(e.value);
    }
  }
  if (!_isNeutral(skin)) {
    for (final e in _aliases.entries) {
      if (skin.contains(e.key)) hits.add(e.value);
    }
  }

  // Order: non‑lumpy first, then lumpy (if present)
  final List<String> ordered = [
    ...hits.where((k) => k != 'lumpy skin disease (lsd)'),
    if (hits.contains('lumpy skin disease (lsd)')) 'lumpy skin disease (lsd)',
  ];

  return ordered
      .where((k) => _suggestions.containsKey(k))
      .map((k) => DiseaseAdvice(disease: _titleCase(k), tips: _suggestions[k]!))
      .toList();
}

String _titleCase(String s) {
  if (s == 'lumpy skin disease (lsd)') return 'Lumpy Skin Disease (LSD)';
  return s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
