import '../../constants/api_constants.dart';

class Lead {
  final int id;
  final String name;
  final String orgName;
  final String? email;
  final String mobile;
  final String? remark;
  final String? leadType;
  final String status;                // merged status from backend
  final String? followUpDate;         // from follow-up table
  final String? visitingCard;

  Lead({
    required this.id,
    required this.name,
    required this.orgName,
    required this.mobile,
    this.email,
    this.remark,
    this.leadType,
    required this.status,
    this.followUpDate,
    this.visitingCard,
  });

  factory Lead.fromJson(Map<String, dynamic> j) {
    return Lead(
      id: j['lead_id'],
      name: j['name'],
      orgName: j['org_name'],
      email: j['email'],
      mobile: j['mobile'],
      remark: j['remark'],
      leadType: j['lead_type'],
      status: j['status'] ?? "pending",
      followUpDate: j['follow_up_date'],
      visitingCard: j['visiting_card_path'] != null
          ? "${ApiConstants.fileURL}/${j['visiting_card_path']}"
          : null,
    );
  }
}
