class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String scannerId;
  final String vendorId;
  final String? phoneNumber;
  final String username;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.scannerId,
    required this.vendorId,
    this.phoneNumber,
    required this.username,
    required this.isActive,
  });
}
