import 'user_model.dart';

class ItemModel {
  final int id;
  final String namaBarang;
  final String deskripsiBarang;
  final String lokasi;
  final String status;
  final String tanggal;
  final String? contactPerson;
  final String? janjiTemu;
  final String? fotoUrl;
  final bool isApproved;
  final UserModel? user;

  ItemModel({
    required this.id,
    required this.namaBarang,
    required this.deskripsiBarang,
    required this.lokasi,
    required this.status,
    required this.tanggal,
    this.contactPerson,
    this.janjiTemu,
    this.fotoUrl,
    this.isApproved = false,
    this.user,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      namaBarang: (json['nama_barang'] as String?) ?? '',
      deskripsiBarang: (json['deskripsi_barang'] as String?) ?? '',
      lokasi: (json['lokasi'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'Lost',
      tanggal: (json['tanggal'] as String?) ?? '',
      contactPerson: json['contact_person'] as String?,
      janjiTemu: json['janji_temu'] as String?,
      fotoUrl: json['foto_url'] as String?,
      isApproved: json['is_approved'] == true || json['is_approved'] == 1,
      user: json['user'] != null ? UserModel.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }
}
