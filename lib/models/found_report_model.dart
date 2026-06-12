import 'item_model.dart';
import 'user_model.dart';
import '../config.dart';

class FoundReportModel {
  final int id;
  final int itemId;
  final String status;
  final String? noTelp;
  final String? lokasi;
  final String? jamJanji;
  final String? fotoUrl;
  final String? createdAt;
  final ItemModel? item;
  final UserModel? finder;

  FoundReportModel({
    required this.id,
    required this.itemId,
    required this.status,
    this.noTelp,
    this.lokasi,
    this.jamJanji,
    this.fotoUrl,
    this.createdAt,
    this.item,
    this.finder,
  });

  factory FoundReportModel.fromJson(Map<String, dynamic> json) {
    return FoundReportModel(
      id: json['id'] as int,
      itemId: json['item_id'] as int,
      status: (json['status'] as String?)?.toLowerCase() ?? 'pending',
      noTelp: json['no_telp'] as String?,
      lokasi: json['lokasi_ambil'] as String? ?? json['lokasi'] as String?,
      jamJanji: json['janji_temu'] as String? ?? json['jam_janji'] as String?,
      fotoUrl: json['foto_bukti_url'] as String? ?? json['foto_url'] as String? ?? (json['foto_bukti'] != null ? '${AppConfig.storageUrl}/${json['foto_bukti']}' : null),
      createdAt: json['created_at'] as String?,
      item: json['item'] != null ? ItemModel.fromJson(json['item'] as Map<String, dynamic>) : null,
      finder: json['finder'] != null ? UserModel.fromJson(json['finder'] as Map<String, dynamic>) : null,
    );
  }
}
