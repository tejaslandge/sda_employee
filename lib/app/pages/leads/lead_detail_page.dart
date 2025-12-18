// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/lead_model.dart';
import '../../models/followup_model.dart';
import '../../../constants/api_constants.dart';

class LeadDetailPage extends StatefulWidget {
  final Lead lead;
  const LeadDetailPage({super.key, required this.lead});

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  List<FollowUp> followUps = [];
  bool loading = true;
  bool apiBusy = false;

  @override
  void initState() {
    super.initState();
    _fetchFollowUps();
  }

  // ================= FETCH FOLLOW UPS =================
  Future<void> _fetchFollowUps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await http.get(
        Uri.parse("${ApiConstants.getFollowUps}/${widget.lead.id}"),
        headers: ApiConstants.authHeaders(token),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['data'] is List) {
          followUps = (decoded['data'] as List)
              .map((e) => FollowUp.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Fetch follow-ups error: $e");
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  // ================= ADD FOLLOW UP =================
  Future<void> _addFollowUp({
    required DateTime date,
    required String remark,
    required String status,
  }) async {
    if (apiBusy) return;
    setState(() => apiBusy = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      await http.post(
        Uri.parse(ApiConstants.addFollowUp),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({
          "lead_id": widget.lead.id,
          "follow_up_date": date.toString().split(" ").first,
          "remark": remark,
          "status": status,
        }),
      );

      await _fetchFollowUps();
    } catch (e) {
      debugPrint("Add follow-up error: $e");
    } finally {
      if (!mounted) return;
      setState(() => apiBusy = false);
    }
  }

  // ================= UPDATE STATUS =================
  Future<void> _updateStatus(int followupId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final url = "${ApiConstants.baseUrl}/api/lead-followups/$followupId/status";

    debugPrint("PUT => $url");
    debugPrint("BODY => {status: $status}");

    final res = await http.put(
      Uri.parse(url),
      headers: ApiConstants.authHeaders(token),
      body: jsonEncode({"status": status}),
    );

    debugPrint("STATUS CODE => ${res.statusCode}");
    // debugPrint("RESPONSE => ${res.body}");

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    await _fetchFollowUps();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(title: const Text("Lead Details"), elevation: 0),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ElevatedButton.icon(
            onPressed: apiBusy ? null : _openAddFollowUpModal,
            icon: const Icon(Icons.add_task),
            label: const Text("Add Follow-Up"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor:
                  Colors.white, // 👈 this ensures text + icon white

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _fetchFollowUps,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _leadHeader(lead),
            const SizedBox(height: 12),
            _leadInfo(lead),
            const SizedBox(height: 24),
            _followUpSection(),
          ],
        ),
      ),
    );
  }

  // ================= LEAD UI =================
  Widget _leadHeader(Lead lead) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lead.name.isNotEmpty ? lead.name : "Unnamed Lead",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          lead.orgName.isNotEmpty ? lead.orgName : "No organization",
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    ),
  );

  Widget _leadInfo(Lead lead) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _card(),
    child: Column(
      children: [
        _row("Mobile", lead.mobile.isNotEmpty ? lead.mobile : "-"),
        if (lead.email != null && lead.email!.isNotEmpty)
          _row("Email", lead.email!),
        if (lead.status == "done")
          _row("status", "Done")
        else
          _row("status", "Pending"),
        // _row("Status", lead.status),
        if (lead.followUpDate != null && lead.followUpDate!.isNotEmpty)
          _row("Next Follow-Up", lead.followUpDate!),
        if (lead.leadType != null && lead.leadType!.isNotEmpty)
          _row("Lead Type", lead.leadType!),
        if (lead.description != null && lead.description!.isNotEmpty)
          _row("Description", lead.description!),
      ],
    ),
  );

  // ================= FOLLOW UPS =================
  Widget _followUpSection() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (followUps.isEmpty) return _emptyFollowUp();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Follow-Up History",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...followUps.map(_followUpTile),
      ],
    );
  }

  Widget _followUpTile(FollowUp f) {
    final done = f.status == "done";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.schedule,
                color: done ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  f.date.isNotEmpty ? f.date : "-",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: apiBusy ? null : () => _openStatusEditModal(f),
                icon: const Icon(Icons.edit_note_rounded),
                tooltip: "Edit Status",
                color: Colors.blueGrey,
              ),
            ],
          ),
          if (f.remark.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                f.remark,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
        ],
      ),
    );
  }

  // ================= MODALS =================
  void _openAddFollowUpModal() {
    DateTime? date;
    String status = "pending";
    final remarkCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const Text(
                    "Add Follow-Up",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // 📅 Date picker card
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => date = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            date == null
                                ? "Select follow-up date"
                                : date!.toString().split(" ").first,
                            style: TextStyle(
                              fontSize: 15,
                              color: date == null
                                  ? Colors.grey.shade600
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📝 Remark field
                  TextField(
                    controller: remarkCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Client remark",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔘 Status pills
                  Row(
                    children: [
                      _statusChip(
                        label: "Pending",
                        active: true, // always pending on add
                        color: Colors.orange,
                        onTap: () {}, // no-op, optional
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ✅ Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (date == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select follow-up date"),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        _addFollowUp(
                          date: date!,
                          remark: remarkCtrl.text,
                          status: status,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Save Follow-Up",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(.15) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _openStatusEditModal(FollowUp f) {
    String status = f.status;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const Text(
                    "Update Follow-Up Status",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // 🔘 Status options
                  Row(
                    children: [
                      Expanded(
                        child: _statusOption(
                          label: "Pending",
                          icon: Icons.schedule,
                          color: Colors.orange,
                          active: status == "pending",
                          onTap: saving
                              ? null
                              : () => setModalState(() => status = "pending"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statusOption(
                          label: "Done",
                          icon: Icons.check_circle,
                          color: Colors.green,
                          active: status == "done",
                          onTap: saving
                              ? null
                              : () => setModalState(() => status = "done"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ✅ Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);

                              try {
                                await _updateStatus(f.id, status);

                                if (!mounted) return;
                                Navigator.pop(context);
                              } catch (e) {
                                setModalState(() => saving = false);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to update status"),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == "done"
                            ? Colors.green
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Update Status",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? color : Colors.grey),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMMON =================
  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(l)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _emptyFollowUp() => Container(
    padding: const EdgeInsets.all(24),
    decoration: _card(),
    child: const Column(
      children: [
        Icon(Icons.event_busy, size: 40),
        SizedBox(height: 10),
        Text(
          "No follow-ups yet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
