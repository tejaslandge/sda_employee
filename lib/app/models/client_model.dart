class ClientModel {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String? profile;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profile,
    this.address,
    this.city,
    this.state,
    this.pincode,
  });

  factory ClientModel.fromJson(Map<String, dynamic> j) {
    return ClientModel(
      id: j['id'],
      name: j['name'],
      email: j['email'],
      mobile: j['mobile'],
      profile: j['profile'],
      address: j['address'],
      city: j['city'],
      state: j['state'],
      pincode: j['pincode'],
    );
  }
}
