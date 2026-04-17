class TrackAsiaPlace {
  final String label;
  final double latitude;
  final double longitude;
  final String? name;
  final String? houseNumber;
  final String? street;
  final String? district;
  final String? city;

  TrackAsiaPlace({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.name,
    this.houseNumber,
    this.street,
    this.district,
    this.city,
  });

  factory TrackAsiaPlace.fromJson(Map<String, dynamic> json) {
    // TrackAsia (Pelias-based) structure
    final geometry = json['geometry'];
    final coordinates = geometry['coordinates'];
    final properties = json['properties'];

    return TrackAsiaPlace(
      label: properties['label'] ?? '',
      latitude: (coordinates[1] as num).toDouble(),
      longitude: (coordinates[0] as num).toDouble(),
      name: properties['name'],
      houseNumber: properties['housenumber'] ?? properties['house_number'],
      street: properties['street'] ?? properties['road'] ?? properties['name'],
      district: properties['district'] ?? properties['county'] ?? properties['locality'],
      city: properties['city'] ?? properties['region'] ?? properties['state'],
    );
  }

  @override
  String toString() => label;
}
