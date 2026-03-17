 class WashroomLocation{
  final String id;
  final String name;
  final double lat;
  final double long;
  final String review;
  final double rating;

  const WashroomLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.long,
    required this.review,
    required this.rating,
  });
}
 
 final List <WashroomLocation> washroomLocations =[
    WashroomLocation(
      id: 'uc_1',
      name: 'Univercity Centre Washroom',
      lat: 43.5316,
      long: -80.2269,
      review: 'Clean and central. Easy to access between classes.',
      rating: 4.2,
    ),
    WashroomLocation(
      id: 'library_1',
      name: 'Library Washroom',
      lat: 43.5311,
      long: -80.2275,
      review: 'Usually quiet, but can get busy during peak study hours.',
      rating: 3.8,
    ),
    WashroomLocation(
      id: 'rozanski_1',
      name: 'Rozanski Washroom',
      lat: 43.5289,
      long: -80.2294,
      review: 'Convenient Location and Generally Well Maintained',
      rating: 3.8,
    ),
    WashroomLocation(
      id: 'mckinnon_1',
      name: 'MacKinnon Washroom',
      lat: 43.5322,
      long: -80.2283,
      review: 'Central and convenient, but can get busy between classes.',
      rating: 3.9,
      ),
      WashroomLocation(
        id: 'war_memorial_1',
        name: 'War Memorial Hall Washroom',
        lat: 43.5307,
        long: -80.2286,
        review: 'Usually clean and easy to find.',
        rating: 4.0,
      ),
      WashroomLocation(
        id: 'science_complex_1',
        name: 'Science Complex Washroom',
        lat: 43.5303,
        long: -80.2298,
        review: 'Spacious and fairly quiet during most of the day.',
        rating: 4.1,
      ),
      WashroomLocation(
        id: 'reynolds_1',
        name: 'Reynolds Walk Washroom',
        lat: 43.5318,
        long: -80.2294,
        review: 'Good location for nearby classes.',
        rating: 3.7,
      ),
      WashroomLocation(
        id: 'thornbrough_1',
        name: 'Thornbrough Washroom',
        lat: 43.5330,
        long: -80.2289,
        review: 'Decent condition and usually not too crowded.',
        rating: 3.8,
      ),
      WashroomLocation(
        id: 'athletics_1',
        name: 'Athletics Centre Washroom',
        lat: 43.5337,
        long: -80.2248,
        review: 'Large washroom and generally maintained well.',
        rating: 4.1,
      ),
  ];
