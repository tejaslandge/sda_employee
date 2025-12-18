import '../../constants/api_constants.dart';

class Lead {
  final int id;
  final String name;
  final String orgName;
  final String mobile;
  final String status;

  final String? email;
  final String? description;
  final String? leadType;
  final String? followUpDate;
  final String? visitingCard;

  Lead({
    required this.id,
    required this.name,
    required this.orgName,
    required this.mobile,
    required this.status,
    this.email,
    this.description,
    this.leadType,
    this.followUpDate,
    this.visitingCard,
  });

  factory Lead.fromJson(Map<String, dynamic> j) {
    return Lead(
      // 🔴 handle BOTH id & lead_id
      id: (j['lead_id'] ?? j['id'] ?? 0) as int,

      // 🔴 force non-null strings
      name: (j['name'] ?? '').toString(),
      orgName: (j['org_name'] ?? '').toString(),
      mobile: (j['mobile'] ?? '').toString(),

      email: j['email']?.toString(),
      description: j['description']?.toString(),
      leadType: j['lead_type']?.toString(),

      // 🔴 normalize status
      status: (j['status'] ?? 'pending').toString(),

      followUpDate: j['follow_up_date']?.toString(),

      visitingCard: j['visiting_card_path'] != null &&
              j['visiting_card_path'].toString().isNotEmpty
          ? "${ApiConstants.fileURL}/${j['visiting_card_path']}"
          : null,
    );
  }
}
