import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'models/item_model.dart';
import 'widgets/logout_dialog.dart';
import 'profile_page.dart';
import 'add_post_page.dart';
import 'app_drawer.dart';

class PostHistoryPage extends StatefulWidget {
  const PostHistoryPage({super.key});

  @override
  State<PostHistoryPage> createState() => _PostHistoryPageState();
}

class _PostHistoryPageState extends State<PostHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchMyItems();
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
          children: [
            _buildAppBar(context, auth),
            Expanded(
              child: Container(
                color: const Color(0xFFDCE6FF),
                child: itemProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : itemProv.error != null
                        ? Center(child: Text(itemProv.error!))
                        : itemProv.myItems.isEmpty
                            ? const Center(child: Text('Belum ada postingan.'))
                        : RefreshIndicator(
                            onRefresh: () => itemProv.fetchMyItems(),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                              itemCount: itemProv.myItems.length,
                              itemBuilder: (ctx, i) => _buildCard(ctx, itemProv.myItems[i]),
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

  Widget _buildCard(BuildContext context, ItemModel item) {
    final isLost = item.status == 'Lost';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: item.fotoUrl != null
                        ? Image.network(item.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _imgPlaceholder())
                        : _imgPlaceholder(),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
                        offset: const Offset(0, 40),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Row(children: const [Icon(Icons.edit, color: Color(0xFF2B65FF)), SizedBox(width: 12), Text('Edit Postingan', style: TextStyle(color: Color(0xFF2B65FF), fontWeight: FontWeight.bold))])),
                          const PopupMenuDivider(),
                          PopupMenuItem(value: 'delete', child: Row(children: const [Icon(Icons.delete, color: Colors.red), SizedBox(width: 12), Text('Hapus Postingan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
                        ],
                        onSelected: (val) {
                          if (val == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddPostPage(editItem: item))).then((_) { if (context.mounted) context.read<ItemProvider>().fetchMyItems(); });
                          } else if (val == 'delete') {
                            _confirmDelete(context, item);
                          }
                        },
                      ),
                    ),
                  ),
                  if (!item.isApproved)
                    Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Menunggu', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                  Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Expanded(child: Text(item.lokasi, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Text(item.status, style: TextStyle(color: isLost ? Colors.red : const Color(0xFF2B65FF), fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: const Color(0xFFE0E0E0),
    child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
  );

  void _confirmDelete(BuildContext context, ItemModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: Text('Yakin ingin menghapus "${item.namaBarang}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final err = await context.read<ItemProvider>().deleteItem(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Postingan berhasil dihapus!')));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, ItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: const Color(0xFFDCE6FF),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFF3F6FF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.grey.shade300, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(ctx))),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('Postingan Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                    ],
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: item.fotoUrl != null
                      ? Image.network(item.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFFE0E0E0), child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey))))
                      : Container(color: const Color(0xFFE0E0E0), child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey))),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailField('Nama Barang', item.namaBarang),
                      const SizedBox(height: 12),
                      _detailField('Deskripsi Barang', item.deskripsiBarang),
                      const SizedBox(height: 12),
                      _detailField('Lokasi', item.lokasi),
                      const SizedBox(height: 12),
                      _detailField('Status', item.status, isStatus: true),
                      if (item.contactPerson != null) ...[
                        const SizedBox(height: 12),
                        _detailField('Contact Person', item.contactPerson!),
                      ],
                      const SizedBox(height: 12),
                      _detailField('Tanggal', item.tanggal),
                      const SizedBox(height: 12),
                      _detailField('Disetujui', item.isApproved ? 'Ya' : 'Menunggu persetujuan admin'),
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

  Widget _detailField(String label, String value, {bool isStatus = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isStatus ? (value == 'Lost' ? Colors.red : const Color(0xFF2B65FF)) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
