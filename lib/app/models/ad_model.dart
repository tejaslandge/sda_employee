class AdModel {
  final int id;
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String filePath;
  final String status;

  AdModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.filePath,
    required this.status,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as int,
      title: json['ad_title'] ?? '',
      type: json['ad_type'] ?? '',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
      filePath: json['file_path'] ?? '',
      status: json['status'] ?? '',
    );
  }

  // ================= DATE FORMATTERS =================

  String get startDateDDMMYYYY => _formatDate(startDate);
  String get endDateDDMMYYYY => _formatDate(endDate);

  // ================= HELPER =================

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$d-$m-$y";
  }
}
