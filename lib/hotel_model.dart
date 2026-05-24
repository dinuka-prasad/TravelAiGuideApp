class Hotel {
  final String id;
  final String name;
  final String location;
  final String image;
  final double rating;
  final double price;
  final String description;
  final List<String> amenities;

  Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.image,
    required this.rating,
    required this.price,
    required this.description,
    required this.amenities,
  });
}
