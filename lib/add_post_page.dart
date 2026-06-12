import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'models/item_model.dart';

import 'widgets/logout_dialog.dart';
import 'profile_page.dart';
import 'app_drawer.dart';
import 'post_history_page.dart';

class AddPostPage extends StatefulWidget {
  final ItemModel? editItem;
  const AddPostPage({super.key, this.editItem});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _namaCtrl = TextEditingController();
  final _deskCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _janjiCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();

  bool _isLost = true;
  File? _pickedImage;
  bool _isSubmitting = false;

  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.editItem!;
      _namaCtrl.text = item.namaBarang;
      _deskCtrl.text = item.deskripsiBarang;
      _lokasiCtrl.text = item.lokasi;
      _contactCtrl.text = item.contactPerson ?? '';
      _janjiCtrl.text = item.janjiTemu ?? '';
      _tanggalCtrl.text = item.tanggal;
      _isLost = item.status == 'Lost';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskCtrl.dispose();
    _lokasiCtrl.dispose();
    _contactCtrl.dispose();
    _janjiCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (img != null) setState(() => _pickedImage = File(img.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
                if (img != null) setState(() => _pickedImage = File(img.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) {
      _tanggalCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_namaCtrl.text.trim().isEmpty || _deskCtrl.text.trim().isEmpty || _lokasiCtrl.text.trim().isEmpty || _tanggalCtrl.text.isEmpty) {
      _showSnack('Nama barang, deskripsi, lokasi, dan tanggal wajib diisi');
      return;
    }
    
    if (!_isLost && _contactCtrl.text.trim().isEmpty) {
      _showSnack('Contact person wajib diisi untuk barang Found');
      return;
    }
    
    if (!_isEditing && _pickedImage == null) {
      _showSnack('Foto barang wajib diisi');
      return;
    }

    setState(() => _isSubmitting = true);

    final itemProv = context.read<ItemProvider>();
    String? error;

    if (_isEditing) {
      error = await itemProv.updateItem(
        id: widget.editItem!.id,
        namaBarang: _namaCtrl.text.trim(),
        deskripsiBarang: _deskCtrl.text.trim(),
        lokasi: _lokasiCtrl.text.trim(),
        status: _isLost ? 'Lost' : 'Found',
        tanggal: _tanggalCtrl.text,
        contactPerson: _contactCtrl.text.trim(),
        janjiTemu: _janjiCtrl.text.trim(),
        fotoPath: _pickedImage?.path,
      );
    } else {
      error = await itemProv.createItem(
        namaBarang: _namaCtrl.text.trim(),
        deskripsiBarang: _deskCtrl.text.trim(),
        lokasi: _lokasiCtrl.text.trim(),
        status: _isLost ? 'Lost' : 'Found',
        tanggal: _tanggalCtrl.text,
        contactPerson: _contactCtrl.text.trim(),
        janjiTemu: _janjiCtrl.text.trim(),
        fotoPath: _pickedImage?.path,
      );
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (error == null) {
      _showSnack(_isEditing ? 'Postingan berhasil diperbarui!' : 'Postingan berhasil dibuat! Menunggu persetujuan admin.');
      if (_isEditing) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PostHistoryPage()));
      }
    } else {
      _showSnack(error);
    }
  }

  void _reset() {
    _namaCtrl.clear();
    _deskCtrl.clear();
    _lokasiCtrl.clear();
    _contactCtrl.clear();
    _janjiCtrl.clear();
    _tanggalCtrl.clear();
    setState(() { _isLost = true; _pickedImage = null; });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFC7D6FF),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppBar(context, auth),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Text(
                _isEditing ? 'Edit Postingan' : 'Tambah Postingan',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: _buildForm()),
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
          Builder(builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: const Icon(Icons.menu, size: 28),
          )),
          const SizedBox(width: 12),
          Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.find_replace, size: 40)),
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
              if (v == 1) { Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, _, _) => const ProfilePage(), transitionDuration: Duration.zero)); }
              if (v == 2) { confirmLogout(context); }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Foto Barang', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: _pickedImage != null
                    ? Image.file(_pickedImage!, height: 120, fit: BoxFit.contain)
                    : (_isEditing && widget.editItem!.fotoUrl != null)
                        ? Image.network(widget.editItem!.fotoUrl!, height: 120, fit: BoxFit.contain, errorBuilder: (_, _, _) => _uploadPlaceholder())
                        : _uploadPlaceholder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nama Barang', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            _field(_namaCtrl, 'Masukkan Nama Barang'),
            const SizedBox(height: 16),
            const Text('Deskripsi Barang', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            _field(_deskCtrl, 'Masukkan Deskripsi Barang', maxLines: 4),
            const SizedBox(height: 16),
            const Text('Lokasi Ditemukan/Hilang', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            _field(_lokasiCtrl, 'Masukkan Lokasi'),
            const SizedBox(height: 16),
            const Text('Status Barang', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Row(
              children: [
                _statusBtn('✓ Found', !_isLost, const Color(0xFF2B65FF), () => setState(() => _isLost = false)),
                const SizedBox(width: 12),
                _statusBtn('! Lost', _isLost, Colors.red, () => setState(() => _isLost = true)),
              ],
            ),
            if (!_isLost) ...[
              const SizedBox(height: 16),
              const Text('Contact Person', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _field(_contactCtrl, 'Nomor telepon aktif', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              const Text('Janji Temu / Lokasi Pengambilan', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _field(_janjiCtrl, 'Contoh: Lobby GKU, Pos Satpam'),
            ],
            const SizedBox(height: 16),
            const Text('Tanggal', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(child: _field(_tanggalCtrl, 'DD/MM/YYYY', icon: Icons.calendar_today)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, color: Colors.white, size: 18),
                    label: Text(_isEditing ? 'Simpan' : 'Posting Sekarang', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B65FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isEditing ? () => Navigator.pop(context) : _reset,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2B65FF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(_isEditing ? 'Batal' : 'Reset', style: const TextStyle(color: Color(0xFF2B65FF), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _uploadPlaceholder() => Column(
    children: const [
      Icon(Icons.image, color: Colors.blue, size: 32),
      SizedBox(height: 8),
      Text('Klik untuk upload foto', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      Text('PNG, JPG, JPEG (maks. 5MB)', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1, IconData? icon, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: icon != null ? Icon(icon, color: Colors.black87, size: 20) : null,
        ),
      ),
    );
  }

  Widget _statusBtn(String text, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(text, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
