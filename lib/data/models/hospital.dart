/// Rumah sakit dari OpenStreetMap beserta jaraknya dari pengguna.
class Hospital {
  const Hospital({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.address = '',
    this.phone = '',
    this.emergency = false,
  });

  final String name;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String address;
  final String phone;
  final bool emergency; // punya IGD menurut data OpenStreetMap
}