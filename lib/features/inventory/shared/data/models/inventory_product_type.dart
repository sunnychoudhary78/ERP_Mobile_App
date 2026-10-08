const inventoryProductTypeApiValues = <String, String>{
  'Physical': 'FINISHED',
  'Tape / roll product (converting)': 'CONVERTING',
  'Service': 'SERVICE',
  'Digital': 'DIGITAL',
};

String? inventoryProductTypeLabel(String? apiValue) {
  if (apiValue == null) return null;
  final normalizedValue = apiValue.trim().toUpperCase();
  if (normalizedValue == 'PHYSICAL') return 'Physical';
  for (final entry in inventoryProductTypeApiValues.entries) {
    if (entry.value == normalizedValue) return entry.key;
  }
  return null;
}
