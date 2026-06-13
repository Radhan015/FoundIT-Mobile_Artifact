import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'models/item_model.dart';
import 'package:quick_actions/quick_actions.dart';
import 'add_post_page.dart';

import 'widgets/logout_dialog.dart';
import 'profile_page.dart';
import 'app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  File? pickedImage;
  bool isSubmitting = false;
  final QuickActions quickActions = const QuickActions();

  @override
  void initState() {
    super.initState();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_add_post') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostPage()));
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'action_add_post', localizedTitle: 'Lapor Barang Hilang'),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
                    : itemProv.items.isEmpty
                        ? const Center(child: Text('Belum ada postingan.'))
                        : RefreshIndicator(
                            onRefresh: () => itemProv.fetchItems(),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                              itemCount: itemProv.items.length,
                              itemBuilder: (ctx, i) => _buildItemCard(ctx, itemProv.items[i], auth),
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
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const Icon(Icons.menu, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.find_replace, size: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (q) => context.read<ItemProvider>().fetchItems(search: q),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildProfileMenu(context, auth),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, AuthProvider auth) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
      child: CircleAvatar(radius: 20, backgroundColor: Colors.white, backgroundImage: auth.user?.fotoUrl != null ? NetworkImage(auth.user!.fotoUrl!) : null, child: auth.user?.fotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth.user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 1, child: Row(children: const [Icon(Icons.person), SizedBox(width: 12), Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold))])),
        PopupMenuItem(value: 2, child: Row(children: const [Icon(Icons.logout, color: Colors.red), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
      ],
      onSelected: (v) {
        if (v == 1) {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, _, _) => const ProfilePage(), transitionDuration: Duration.zero));
        } else if (v == 2) {
          confirmLogout(context);
        }
      },
    );
  }

  Widget _buildItemCard(BuildContext context, ItemModel item, AuthProvider auth) {
    final isLost = item.status == 'Lost';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showItemDetails(context, item, auth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.fotoUrl != null
                    ? Image.network(item.fotoUrl!, fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, _, _) => _imgPlaceholder())
                    : _imgPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.lokasi, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
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

  void _showItemDetails(BuildContext context, ItemModel item, AuthProvider auth) {
    final isOwner = auth.user?.id == item.user?.id;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: const Color(0xFFDCE6FF),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFF0F0F0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(ctx)),
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: item.user?.fotoUrl != null ? NetworkImage(item.user!.fotoUrl!) : null,
                        child: item.user?.fotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(item.user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: item.fotoUrl != null
                      ? Image.network(item.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _imgPlaceholder())
                      : _imgPlaceholder(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailField('Nama Barang', item.namaBarang),
                      const SizedBox(height: 12),
                      _detailField('Deskripsi Barang', item.deskripsiBarang),
                      const SizedBox(height: 12),
                      _detailField('Lokasi', item.lokasi),
                      const SizedBox(height: 12),
                      _detailField('Status', item.status, valueColor: item.status == 'Lost' ? Colors.red : const Color(0xFF2B65FF)),
                      const SizedBox(height: 12),
                      _detailField('Tanggal', item.tanggal),
                      if (item.contactPerson != null) ...[
                        const SizedBox(height: 12),
                        _detailField('Contact Person', item.contactPerson!),
                      ],
                      if (item.status == 'Lost') ...[
                        if (!isOwner) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showVerificationDialog(context, item);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B65FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Found it!', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final err = await context.read<ItemProvider>().deleteItem(item.id);
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (err == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item ditandai sebagai sudah ditemukan (dihapus)')));
                                  context.read<ItemProvider>().fetchItems(); // Refresh home
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                              icon: const Icon(Icons.check_box, color: Colors.white),
                              label: const Text('Already Found', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
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

  void _showVerificationDialog(BuildContext context, ItemModel item) {
    final auth = context.read<AuthProvider>();
    final noTelpCtrl = TextEditingController(text: auth.user?.noTelp ?? '');
    final lokasiCtrl = TextEditingController(text: item.lokasi);
    final jamCtrl = TextEditingController();
    final tanggalCtrl = TextEditingController();
    File? pickedImage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: const Color(0xFFDCE6FF),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: const Color(0xFFDCE6FF),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(ctx)),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('Verifikasi\nbarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Foto Bukti Penemuan *'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final source = await showModalBottomSheet<ImageSource>(
                              context: context,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                              builder: (_) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Pilih dari Galeri'),
                                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Ambil dari Kamera'),
                                      onTap: () => Navigator.pop(context, ImageSource.camera),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (source != null) {
                              final img = await picker.pickImage(
                                source: source,
                                imageQuality: 60,
                                maxWidth: 1024,
                              );
                              if (img != null) setS(() => pickedImage = File(img.path));
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: pickedImage != null
                                ? Image.file(pickedImage!, height: 100, fit: BoxFit.contain)
                                : Column(
                                    children: const [
                                      Icon(Icons.image, color: Colors.blue, size: 32),
                                      SizedBox(height: 8),
                                      Text('Klik untuk upload foto', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                      Text('PNG, JPG (maks. 5MB)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Nomor Telepon *'),
                        const SizedBox(height: 6),
                        _inputField(ctrl: noTelpCtrl, hint: 'Contoh: 08123456789', keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        const Text('📍 Lokasi Pengambilan Barang *'),
                        const SizedBox(height: 6),
                        _inputField(ctrl: lokasiCtrl, hint: 'Contoh: Lobby GKU, Kantin TULT...'),
                        const SizedBox(height: 12),
                        const Text('📅 Tanggal & Jam Janji Temu *'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _inputField(
                              ctrl: tanggalCtrl,
                              hint: 'YYYY-MM-DD',
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (d != null) {
                                  tanggalCtrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                }
                              },
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _inputField(
                              ctrl: jamCtrl,
                              hint: '--:--',
                              icon: Icons.access_time,
                              readOnly: true,
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (t != null) {
                                  jamCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
                                }
                              },
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (pickedImage == null || noTelpCtrl.text.trim().isEmpty || lokasiCtrl.text.trim().isEmpty || tanggalCtrl.text.trim().isEmpty || jamCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom dan foto wajib diisi!'), backgroundColor: Colors.red));
                                      return;
                                    }
                                    setS(() => isSubmitting = true);
                                    final janji = '${tanggalCtrl.text} ${jamCtrl.text}'.trim();
                                    final err = await context.read<ItemProvider>().submitFoundReport(
                                      itemId: item.id,
                                      noTelp: noTelpCtrl.text.trim(),
                                      lokasi: lokasiCtrl.text.trim(),
                                      jamJanji: janji,
                                      fotoPath: pickedImage!.path,
                                    );
                                    setS(() => isSubmitting = false);
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(err ?? 'Laporan berhasil dikirim!'),
                                    ));
                                  },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B65FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Kirim Verifikasi', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailField(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: TextStyle(fontSize: 15, color: valueColor ?? Colors.black87)),
        ),
      ],
    );
  }

  Widget _inputField({TextEditingController? ctrl, String? hint, IconData? icon, TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: icon != null ? Icon(icon, color: Colors.black87) : null,
        ),
      ),
    );
  }
}
