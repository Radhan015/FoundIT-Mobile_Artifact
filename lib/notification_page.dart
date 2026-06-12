import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'models/found_report_model.dart';

import 'widgets/logout_dialog.dart';
import 'profile_page.dart';
import 'app_drawer.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final itemProv = context.watch<ItemProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFC7D6FF),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context, auth),
            Container(
              color: const Color(0xFFDCE6FF),
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: const Text('Penemuan Barang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFDCE6FF),
                child: itemProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : itemProv.notifications.isEmpty
                        ? const Center(child: Text('Belum ada laporan penemuan.'))
                        : RefreshIndicator(
                            onRefresh: () => itemProv.fetchNotifications(),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.68,
                              ),
                              itemCount: itemProv.notifications.length,
                              itemBuilder: (ctx, i) => _buildCard(ctx, itemProv.notifications[i]),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Builder(builder: (ctx) => GestureDetector(onTap: () => Scaffold.of(ctx).openDrawer(), child: const Icon(Icons.menu, size: 28))),
          const SizedBox(width: 12),
          Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.find_replace, size: 40)),
          const SizedBox(width: 12),
          const Spacer(),
          const SizedBox(width: 12),
          PopupMenuButton<int>(
            offset: const Offset(0, 50), color: Colors.white, elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
            child: CircleAvatar(radius: 20, backgroundColor: Colors.white, backgroundImage: auth.user?.fotoUrl != null ? NetworkImage(auth.user!.fotoUrl!) : null, child: auth.user?.fotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null),
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 1, child: const Row(children: [Icon(Icons.person), SizedBox(width: 12), Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold))])),
              PopupMenuItem(value: 2, child: const Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
            ],
            onSelected: (v) {
              if (v == 1) Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, _, _) => const ProfilePage(), transitionDuration: Duration.zero));
              if (v == 2) { confirmLogout(context); }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, FoundReportModel report) {
    final isConfirmed = report.status == 'claimed' || report.status == 'confirmed';
    final isRejected = report.status == 'invalid' || report.status == 'rejected';
    final item = report.item;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, report),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: report.fotoUrl != null
                        ? Image.network(report.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _imgPlaceholder())
                        : _imgPlaceholder(),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConfirmed ? Colors.green.withValues(alpha: 0.85) : isRejected ? Colors.red.withValues(alpha: 0.75) : Colors.orange.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isConfirmed ? Icons.check : isRejected ? Icons.close : Icons.hourglass_empty, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(isConfirmed ? 'Dikonfirmasi' : isRejected ? 'Ditolak' : 'Pending', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item?.namaBarang ?? 'Barang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Expanded(child: Text(report.lokasi ?? item?.lokasi ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Text('Dilaporkan oleh: ${report.finder?.name ?? 'Unknown'}', style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(color: const Color(0xFFE0E0E0), child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)));

  void _showDetails(BuildContext context, FoundReportModel report) {
    final item = report.item;
    final finder = report.finder;
    final isWaitingOwner = report.status == 'approved';
    final isPendingAdmin = report.status == 'pending';
    final isConfirmed = report.status == 'claimed' || report.status == 'confirmed';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFDCE6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(right: 36),
                            child: Text('🎉 Barang Ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: report.fotoUrl != null
                      ? Image.network(report.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFFE0E0E0), child: const Center(child: Icon(Icons.image, size: 60, color: Colors.grey))))
                      : Container(color: const Color(0xFFE0E0E0), child: const Center(child: Icon(Icons.image, size: 60, color: Colors.grey))),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailField('Nama Barang', item?.namaBarang ?? '-'),
                      const SizedBox(height: 12),
                      _detailField('Deskripsi', item?.deskripsiBarang ?? '-'),
                      const SizedBox(height: 12),
                      _detailField('Lokasi', report.lokasi ?? item?.lokasi ?? '-'),
                      const SizedBox(height: 12),
                      _detailField('Penemu', finder?.name ?? '-'),
                      const SizedBox(height: 12),
                      _detailField('No. Telepon Penemu', report.noTelp ?? finder?.noTelp ?? '-'),
                      if (report.jamJanji != null) ...[
                        const SizedBox(height: 12),
                        _detailField('Jam & Janji Temu', report.jamJanji!),
                      ],
                      if (isWaitingOwner) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final err = await context.read<ItemProvider>().confirmReport(report.id);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Barang dikonfirmasi!')));
                            },
                            icon: const Icon(Icons.check_box, color: Colors.white),
                            label: const Text('Ya, itu barang saya!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final err = await context.read<ItemProvider>().rejectReport(report.id);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Laporan ditolak.')));
                            },
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Bukan barang saya', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                            style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                      ] else if (isPendingAdmin) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text('Menunggu Persetujuan Admin', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isConfirmed ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isConfirmed ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isConfirmed ? Icons.check_circle : Icons.close, color: isConfirmed ? Colors.green : Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(isConfirmed ? 'Barang Sudah Dikonfirmasi' : 'Laporan Ditolak', style: TextStyle(color: isConfirmed ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
