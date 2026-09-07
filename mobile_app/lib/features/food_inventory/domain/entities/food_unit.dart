/// Units of measurement for food items
enum FoodUnit {
  pieces('Pieces', 'pcs'),
  kg('Kilograms', 'kg'),
  grams('Grams', 'g'),
  litre('Litres', 'L'),
  ml('Millilitres', 'ml'),
  portions('Portions', 'portions'),
  cups('Cups', 'cups'),
  containers('Containers', 'containers');

  final String displayName;
  final String abbreviation;

  const FoodUnit(this.displayName, this.abbreviation);

  String get label => displayName;

  static FoodUnit fromString(String val) {
    return FoodUnit.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() ||
             e.abbreviation.toLowerCase() == val.toLowerCase() ||
             e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => FoodUnit.pieces,
    );
  }
}
