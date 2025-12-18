import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/api_constants.dart';
import '../../models/lead_model.dart';
import 'create_lead_page.dart';
import 'lead_detail_page.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  List<Lead> leads = [];
  bool loading = true;

  String searchQuery = "";
  String selectedFilter = "all";
  String sortType = "newest";

  @override
  void initState() {
    super.initState();
    fetchLeads();
  }

  // ================= FETCH =================
  Future<void> fetchLeads() async {
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

  // ================= FILTER / SORT =================
  List<Lead> _filteredLeads() {
    List<Lead> list = [...leads];

    if (selectedFilter != "all") {
      list = list.where((l) => l.status == selectedFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((l) {
        return l.name.toLowerCase().contains(q) ||
            l.orgName.toLowerCase().contains(q) ||
            l.mobile.contains(q);
      }).toList();
    }

    switch (sortType) {
      case "newest":
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case "oldest":
        list.sort((a, b) => a.id.compareTo(b.id));
        break;
      case "az":
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case "za":
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    return list;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLeads();

    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(
        title: const Text("Leads"),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _openSortSheet),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateLeadPage()),
          );
          fetchLeads();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _searchBar(),
          _filterChips(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(child: Text("No leads found"))
                : RefreshIndicator(
                    onRefresh: fetchLeads,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _leadCard(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ================= SEARCH =================
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: InputDecoration(
          hintText: "Search by name, org or mobile",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ================= FILTER CHIPS =================
  Widget _filterChips() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [_chip("All", "all"), _chip("Pending", "pending")],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final active = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        selectedColor: Colors.blue.withOpacity(.2),
        onSelected: (_) => setState(() => selectedFilter = value),
      ),
    );
  }

  // ================= LEAD CARD =================
  Widget _leadCard(Lead l) {
    final isDone = l.status == "completed" || l.status == "done";

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LeadDetailPage(lead: l)),
        );
        fetchLeads();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _makeCall(l.mobile),
                  icon: const Icon(Icons.call),
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.orgName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "📞 ${l.mobile}",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _badge(l.leadType ?? "Other"),
                const SizedBox(width: 8),
                _statusBadge(isDone),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusBadge(bool done) {
    final color = done ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        done ? "DONE" : "PENDING",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ================= SORT =================
  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortTile("Newest first", "newest"),
            _sortTile("Oldest first", "oldest"),
            _sortTile("Name A–Z", "az"),
            _sortTile("Name Z–A", "za"),
          ],
        );
      },
    );
  }

  Widget _sortTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: sortType == value
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() => sortType = value);
        Navigator.pop(context);
      },
    );
  }

  // ================= CALL =================
  Future<void> _makeCall(String number) async {
    final uri = Uri(scheme: "tel", path: number);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
