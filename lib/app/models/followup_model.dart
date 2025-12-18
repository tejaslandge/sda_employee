class FollowUp {
  final int id;
  final String date;
  final String remark;
  final String status;

  FollowUp({
    required this.id,
    required this.date,
    required this.remark,
    required this.status,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      // 🔴 support both id & followup_id
      id: (json['followup_id'] ?? json['id'] ?? 0) as int,

      // 🔴 always string
      date: (json['follow_up_date'] ?? '').toString(),

      // 🔴 remark safe
      remark: (json['remark'] ?? '').toString(),

      // 🔴 normalize status
      status: (json['status'] ?? 'pending').toString(),
    );
  }
}
