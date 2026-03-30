 class WashroomLocation{
  final String id;
  final String name;
  final double lat;
  final double long;
  final String review;
  final double rating;
  final bool isAccessible;
  final bool isGenderNeutral;
  final bool isSingleStall;

  const WashroomLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.long,
    required this.review,
    required this.rating,
    this.isAccessible = false,
    this.isGenderNeutral = false,
    this.isSingleStall = false,
  });
}
 