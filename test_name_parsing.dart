// Quick test to verify the name parsing logic
// This file is for testing purposes only and can be deleted after verification

void main() {
  print('Testing name parsing logic:');

  // Test cases based on real user data patterns
  final testCases = [
    'Dr. Sarah Johnson',
    'Dr. Michael Chen',
    'Dr. Jennifer Liu',
    'Sarah Johnson',
    'Dr.Sarah', // edge case
    'Dr. ', // edge case
    '', // edge case
    'Prof. John Smith',
    'Mr. David Wilson',
  ];

  for (final name in testCases) {
    final firstName = getFirstName(name);
    print('Input: "$name" -> First Name: "$firstName"');
  }
}

String getFirstName(String? name) {
  if (name == null || name.trim().isEmpty) return 'Doctor';

  // Clean the name and split into parts
  String cleanName = name.trim().replaceAll(
    RegExp(r'[^\w\s]'),
    ' ',
  ); // Replace punctuation with spaces
  List<String> parts =
      cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

  if (parts.isEmpty) return 'Doctor';

  // Skip common titles and get the actual first name
  final titlesToSkip = {'dr', 'prof', 'professor', 'mr', 'ms', 'mrs', 'miss'};

  for (final part in parts) {
    if (!titlesToSkip.contains(part.toLowerCase())) {
      // Return the first non-title word, properly capitalized
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }
  }

  // If all parts are titles, return fallback
  return 'Doctor';
}
