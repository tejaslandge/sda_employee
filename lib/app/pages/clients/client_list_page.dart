import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../models/client_model.dart';
import 'client_profile_page.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  List<ClientModel> clients = [];
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    setState(() {
      loading = true;
      error = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await http.get(
        Uri.parse(ApiConstants.clients),
        headers: ApiConstants.authHeaders(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)["data"] as List;
        clients = data.map((e) => ClientModel.fromJson(e)).toList();
      } else {
        error = true;
      }
    } catch (_) {
      error = true;
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Clients"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error
          ? _errorState()
          : RefreshIndicator(
              onRefresh: fetchClients,
              child: clients.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _clientCard(context, clients[i]),
                    ),
            ),
    );
  }

  Widget _clientCard(BuildContext context, ClientModel c) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClientProfilePage(client: c)),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueGrey.shade100,
                backgroundImage: c.profile != null
                    ? NetworkImage(c.profile!)
                    : null,
                child: c.profile == null
                    ? const Icon(Icons.person, size: 32, color: Colors.white)
                    : null,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      c.mobile,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    if ((c.city ?? "").isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.city!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.group_off, size: 90, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                "No clients assigned",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text("Failed to load clients", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: fetchClients, child: const Text("Retry")),
        ],
      ),
    );
  }
}
