import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../models/client_model.dart';
import '../../models/ad_model.dart';
import 'upload_ad_page.dart';
import 'ad_video_player_page.dart';

class ClientProfilePage extends StatefulWidget {
  final ClientModel client;

  const ClientProfilePage({super.key, required this.client});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  late Future<List<AdModel>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _adsFuture = _fetchClientAds(widget.client.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.client;

    final addressLine = (c.address ?? "").trim();
    final locationLine = [
      c.city,
      c.state,
      c.pincode,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(", ");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Client Profile"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= PROFILE CARD =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.blueGrey.shade100,
                    backgroundImage: c.profile != null
                        ? NetworkImage("${c.profile}")
                        : null,
                    child: c.profile == null
                        ? const Icon(Icons.person, size: 54)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(c.mobile, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  if (addressLine.isNotEmpty)
                    Text(
                      addressLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  if (locationLine.isNotEmpty)
                    Text(
                      locationLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= ACTION BUTTONS =================
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: _primaryButtonStyle(),
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload Ad"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UploadAdPage(clientId: c.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: _secondaryButtonStyle(),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("View Ads"),
                    onPressed: () => _showAdsBottomSheet(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= BOTTOM SHEET =================

  void _showAdsBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: FutureBuilder<List<AdModel>>(
              future: _adsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No ads uploaded"));
                }

                final ads = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _adTile(ads[i]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ================= AD TILE =================

  Widget _adTile(AdModel ad) {
    final String mediaUrl = ad.filePath.startsWith('http')
        ? ad.filePath
        : "${ApiConstants.fileURL}/${ad.filePath}";

    final String lower = ad.filePath.toLowerCase();
    final bool isImage =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    final bool isVideo = lower.endsWith('.mp4') || lower.endsWith('.mov');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop(); // close bottom sheet
              await Future.delayed(const Duration(milliseconds: 200));

              if (!mounted) return;

              if (isVideo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdVideoPlayerPage(videoUrl: mediaUrl),
                  ),
                );
              } else if (isImage) {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black,
                    child: InteractiveViewer(child: Image.network(mediaUrl)),
                  ),
                );
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isImage
                  ? Image.network(
                      mediaUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: Colors.black12,
                      child: const Icon(Icons.play_circle_fill, size: 42),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Type: ${ad.type}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "Start Date: ${ad.startDateDDMMYYYY}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "End Date: ${ad.endDateDDMMYYYY}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 6),
                _statusChip(ad.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= API =================

  Future<List<AdModel>> _fetchClientAds(int clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final res = await http.get(
      Uri.parse("${ApiConstants.clientAds}/$clientId/ads"),
      headers: ApiConstants.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded['data'] ?? [];
      return list.map((e) => AdModel.fromJson(e)).toList();
    }

    return [];
  }

  // ================= HELPERS =================

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
