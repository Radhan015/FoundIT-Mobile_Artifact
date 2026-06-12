import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../models/found_report_model.dart';
import '../services/api_service.dart';

class ItemProvider extends ChangeNotifier {
  List<ItemModel> _items = [];
  List<ItemModel> _myItems = [];
  List<FoundReportModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<ItemModel> get items => _items;
  List<ItemModel> get myItems => _myItems;
  List<FoundReportModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchItems({String? search, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String>[];
      if (search != null && search.isNotEmpty) params.add('search=$search');
      if (status != null && status.isNotEmpty) params.add('status=$status');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final response = await ApiService.get('/items$query');
      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        _items = (data['data'] as List)
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Gagal memuat data';
      }
    } catch (e) {
      _error = 'Koneksi ke server gagal';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/items/history');
      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        _myItems = (data['data'] as List)
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Gagal memuat data';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createItem({
    required String namaBarang,
    required String deskripsiBarang,
    required String lokasi,
    required String status,
    required String tanggal,
    String? contactPerson,
    String? janjiTemu,
    String? fotoPath,
  }) async {
    try {
      final fields = <String, String>{
        'nama_barang': namaBarang,
        'deskripsi_barang': deskripsiBarang,
        'lokasi': lokasi,
        'status': status,
        'tanggal': tanggal,
      };
      if (contactPerson != null && contactPerson.isNotEmpty) fields['contact_person'] = contactPerson;
      if (janjiTemu != null && janjiTemu.isNotEmpty) fields['janji_temu'] = janjiTemu;

      final streamed = await ApiService.postMultipart('/items', fields, filePath: fotoPath);
      final data = await ApiService.parseStreamedResponse(streamed);

      if (streamed.statusCode == 201) {
        await fetchMyItems();
        return null;
      }
      return (data['message'] as String?) ?? 'Gagal membuat postingan';
    } catch (e) {
      return 'Koneksi ke server gagal';
    }
  }

  Future<String?> updateItem({
    required int id,
    required String namaBarang,
    required String deskripsiBarang,
    required String lokasi,
    required String status,
    required String tanggal,
    String? contactPerson,
    String? janjiTemu,
    String? fotoPath,
  }) async {
    try {
      final fields = <String, String>{
        'nama_barang': namaBarang,
        'deskripsi_barang': deskripsiBarang,
        'lokasi': lokasi,
        'status': status,
        'tanggal': tanggal,
      };
      if (contactPerson != null && contactPerson.isNotEmpty) fields['contact_person'] = contactPerson;
      if (janjiTemu != null && janjiTemu.isNotEmpty) fields['janji_temu'] = janjiTemu;

      final streamed = await ApiService.postMultipart('/items/$id/update', fields, filePath: fotoPath);
      final data = await ApiService.parseStreamedResponse(streamed);

      if (streamed.statusCode == 200) {
        await fetchMyItems();
        return null;
      }
      return (data['message'] as String?) ?? 'Gagal memperbarui postingan';
    } catch (e) {
      return 'Koneksi ke server gagal';
    }
  }

  Future<String?> deleteItem(int id) async {
    try {
      final response = await ApiService.delete('/items/$id');
      if (response.statusCode == 200) {
        _myItems.removeWhere((i) => i.id == id);
        notifyListeners();
        return null;
      }
      final data = ApiService.parseResponse(response);
      return (data['message'] as String?) ?? 'Gagal menghapus';
    } catch (e) {
      return 'Koneksi ke server gagal';
    }
  }

  Future<String?> submitFoundReport({
    required int itemId,
    String? noTelp,
    String? lokasi,
    String? jamJanji,
    String? fotoPath,
  }) async {
    try {
      final fields = <String, String>{
        'item_id': itemId.toString(),
      };
      if (noTelp != null && noTelp.isNotEmpty) fields['no_telp'] = noTelp;
      if (lokasi != null && lokasi.isNotEmpty) fields['lokasi_ambil'] = lokasi;
      if (jamJanji != null && jamJanji.isNotEmpty) fields['janji_temu'] = jamJanji;

      final streamed = await ApiService.postMultipart('/verification', fields, filePath: fotoPath, fileField: 'foto_bukti');
      final data = await ApiService.parseStreamedResponse(streamed);

      if (streamed.statusCode == 201) return null;
      if (streamed.statusCode == 422 && data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        return errors.values.first[0] as String;
      }
      return (data['message'] as String?) ?? 'Gagal mengirim laporan';
    } catch (e) {
      return 'Koneksi ke server gagal';
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/notifications');
      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        _notifications = (data['data'] as List)
            .map((e) => FoundReportModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> confirmReport(int reportId) async {
    try {
      final response = await ApiService.post('/verifikasi/$reportId/status', {'status': 'claimed'});
      if (response.statusCode == 200) {
        final idx = _notifications.indexWhere((r) => r.id == reportId);
        if (idx >= 0) {
          _notifications[idx] = FoundReportModel.fromJson({
            ..._notificationJson(_notifications[idx]),
            'status': 'claimed',
          });
          notifyListeners();
        }
        return null;
      }
      return 'Gagal mengkonfirmasi';
    } catch (_) {
      return 'Koneksi ke server gagal';
    }
  }

  Future<String?> rejectReport(int reportId) async {
    try {
      final response = await ApiService.post('/verifikasi/$reportId/status', {'status': 'invalid'});
      if (response.statusCode == 200) {
        final idx = _notifications.indexWhere((r) => r.id == reportId);
        if (idx >= 0) {
          _notifications[idx] = FoundReportModel.fromJson({
            ..._notificationJson(_notifications[idx]),
            'status': 'invalid',
          });
          notifyListeners();
        }
        return null;
      }
      return 'Gagal menolak';
    } catch (_) {
      return 'Koneksi ke server gagal';
    }
  }

  Map<String, dynamic> _notificationJson(FoundReportModel r) => {
    'id': r.id,
    'item_id': r.itemId,
    'status': r.status,
    'no_telp': r.noTelp,
    'lokasi': r.lokasi,
    'jam_janji': r.jamJanji,
    'foto_url': r.fotoUrl,
    'created_at': r.createdAt,
    'item': r.item != null ? {
      'id': r.item!.id,
      'nama_barang': r.item!.namaBarang,
      'deskripsi_barang': r.item!.deskripsiBarang,
      'lokasi': r.item!.lokasi,
      'status': r.item!.status,
      'tanggal': r.item!.tanggal,
      'foto_url': r.item!.fotoUrl,
    } : null,
    'finder': r.finder != null ? {
      'id': r.finder!.id,
      'name': r.finder!.name,
      'username': r.finder!.username,
      'no_telp': r.finder!.noTelp,
    } : null,
  };
}
