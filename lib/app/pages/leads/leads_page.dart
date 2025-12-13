import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/api_constants.dart';
import '../../models/lead_model.dart';
import 'create_lead_page.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  List<Lead> leads = [];
  bool loading = true;

  String selectedFilter = "all";
  String searchQuery = "";
  String sortType = "newest";

  @override
  void initState() {
    super.initState();
    fetchLeads();
  }

  // ---------------- FETCH LEADS ----------------
  fetchLeads() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final res = await http.get(
      Uri.parse(ApiConstants.leads),
      headers: ApiConstants.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      leads = (data as List).map((e) => Lead.fromJson(e)).toList();
    }

    setState(() => loading = false);
  }

  // ---------------- MAKE PHONE CALL ----------------
  Future<void> _makePhoneCall(String number) async {
    final uri = Uri(scheme: "tel", path: number);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open dialer")),
      );
    }
  }

  // ---------------- UPDATE FOLLOW-UP ----------------
  Future<void> _updateFollowUp(
      int id, String remark, String status, DateTime? nextDate) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final body = {
      "remark": remark,
      "status": status,
      "follow_up_date":
          nextDate != null ? nextDate.toString().split(" ").first : null,
    };

    await http.post(
      Uri.parse("${ApiConstants.baseUrl}/update-followup/$id"),
      headers: ApiConstants.authHeaders(token),
      body: body,
    );

    fetchLeads();
  }

  // ---------------- FILTER + SEARCH + SORT ----------------
  List<Lead> _filteredLeads() {
    List<Lead> filtered = [...leads];

    if (selectedFilter != "all") {
      filtered = filtered.where((l) => l.status == selectedFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where((l) =>
              l.name.toLowerCase().contains(q) ||
              l.orgName.toLowerCase().contains(q) ||
              l.mobile.contains(q))
          .toList();
    }

    const typeOrder = {
      "Display": 1,
      "Ads": 2,
      "Referral": 3,
      "Cold Call": 4,
      "Website": 5,
      "Other": 6,
    };

    switch (sortType) {
      case "newest":
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;

      case "oldest":
        filtered.sort((a, b) => a.id.compareTo(b.id));
        break;

      case "az":
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;

      case "za":
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;

      case "type_az":
        filtered.sort((a, b) =>
            (typeOrder[a.leadType] ?? 99).compareTo(typeOrder[b.leadType] ?? 99));
        break;

      case "type_za":
        filtered.sort((a, b) =>
            (typeOrder[b.leadType] ?? 99).compareTo(typeOrder[a.leadType] ?? 99));
        break;
    }

    return filtered;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLeads();

    return Scaffold(
      appBar: AppBar(title: const Text("Leads")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateLeadPage()),
          );
          fetchLeads();
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _searchFilterSort(),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("No leads found"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _leadCard(filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  // ---------------- SEARCH + FILTER + SORT UI ----------------
  Widget _searchFilterSort() {
    List<Map<String, dynamic>> chipItems = [
      {"label": "All", "key": "status_all", "icon": Icons.list},
      {"label": "Pending", "key": "status_pending", "icon": Icons.hourglass_empty},
      {"label": "Completed", "key": "status_completed", "icon": Icons.check_circle},

      {"label": "Newest", "key": "sort_newest", "icon": Icons.auto_awesome},
      {"label": "Oldest", "key": "sort_oldest", "icon": Icons.history},
      {"label": "A–Z", "key": "sort_az", "icon": Icons.sort_by_alpha},
      {"label": "Z–A", "key": "sort_za", "icon": Icons.sort_by_alpha},
      {"label": "Type A–Z", "key": "sort_type_az", "icon": Icons.category},
      {"label": "Type Z–A", "key": "sort_type_za", "icon": Icons.category},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            decoration: InputDecoration(
              hintText: "Search leads...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                chipItems.map((item) => _premiumChip(item)).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- CHIP UI ----------------
  Widget _premiumChip(Map<String, dynamic> item) {
    String key = item["key"];
    String label = item["label"];
    IconData icon = item["icon"];

    bool active = false;

    if (key.startsWith("status")) {
      String val = key.replaceFirst("status_", "");
      active = selectedFilter == val;
    } else {
      String val = key.replaceFirst("sort_", "");
      active = sortType == val;
    }

    return GestureDetector(
      onTap: () {
        if (key.startsWith("status")) {
          selectedFilter = key.replaceFirst("status_", "");
        } else {
          sortType = key.replaceFirst("sort_", "");
        }
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : Colors.black87),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: active ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ---------------- LEAD CARD ----------------
  Widget _leadCard(Lead l) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAME + CALL + EDIT BUTTON
          Row(
            children: [
              Expanded(
                child: Text(l.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              InkWell(
                onTap: () => _makePhoneCall(l.mobile),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.call, color: Colors.green),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openFollowUpModal(l),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_note_rounded,
                      color: Colors.blue, size: 26),
                ),
              )
            ],
          ),

          const SizedBox(height: 6),
          Text(l.orgName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),

          const SizedBox(height: 6),
          Text("📞 ${l.mobile}",
              style: TextStyle(color: Colors.grey.shade700)),

          if (l.email != null)
            Text("✉️ ${l.email}",
                style: TextStyle(color: Colors.grey.shade700)),

          const SizedBox(height: 10),

          Row(
            children: [
              _leadTypeBadge(l.leadType ?? "Other"),
              const SizedBox(width: 8),
              _statusBadge(l.status),
            ],
          ),

          if (l.followUpDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text("Next Follow-up: ${l.followUpDate}",
                  style: TextStyle(color: Colors.grey.shade600)),
            ),

          if (l.remark != null && l.remark!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Remark:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold)),
                  Text(l.remark!,
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            )
        ],
      ),
    );
  }

  // ---------------- FOLLOW-UP MODAL ----------------
  void _openFollowUpModal(Lead l) {
    TextEditingController remarkCtrl =
        TextEditingController(text: l.remark ?? "");

    String newStatus = l.status;
    DateTime? nextDate = l.followUpDate != null
        ? DateTime.tryParse(l.followUpDate!)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Update Follow-Up Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 15),

                  TextField(
                    controller: remarkCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Client Remark (Client ne kya bola?)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: nextDate ?? DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setModalState(() => nextDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month),
                          const SizedBox(width: 10),
                          Text(nextDate == null
                              ? "Select next follow-up date"
                              : nextDate.toString().split(" ").first),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Pending"),
                        selected: newStatus == "pending",
                        onSelected: (_) =>
                            setModalState(() => newStatus = "pending"),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("Completed"),
                        selected: newStatus == "completed",
                        onSelected: (_) =>
                            setModalState(() => newStatus = "completed"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateFollowUp(
                            l.id, remarkCtrl.text, newStatus, nextDate);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("Save Changes",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- TYPE BADGE ----------------
  Widget _leadTypeBadge(String type) {
    final colors = {
      "Display": Colors.green,
      "Ads": Colors.blue,
      "Referral": Colors.purple,
      "Cold Call": Colors.orange,
      "Website": Colors.teal,
      "Other": Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
          color: colors[type]!.withOpacity(.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(type,
          style: TextStyle(
              color: colors[type],
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }

  // ---------------- STATUS BADGE ----------------
  Widget _statusBadge(String status) {
    final colors = {
      "pending": Colors.orange,
      "completed": Colors.green,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
          color: (colors[status] ?? Colors.grey).withOpacity(.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: colors[status] ?? Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12),
      ),
    );
  }
}
