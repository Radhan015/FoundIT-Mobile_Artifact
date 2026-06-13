import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> checkAuth() async {
    final token = await ApiService.getToken();
    if (token == null) return false;
    try {
      final response = await ApiService.get('/profile');
      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        _user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        notifyListeners();
        return true;
      }
      await ApiService.clearToken();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/login',
        {'username': username, 'password': password},
        auth: false,
      );
      final data = ApiService.parseResponse(response);

      if (response.statusCode == 200) {
        final responseData = data['data'] as Map<String, dynamic>;
        await ApiService.setToken(responseData['access_token'] as String);
        _user = UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _error = (data['message'] as String?) ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return _error;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<String?> register({
    required String fullname,
    required String username,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/register',
        {
          'fullname': fullname,
          'username': username,
          'phone': phone,
          'email': email,
          'password': password,
        },
        auth: false,
      );
      final data = ApiService.parseResponse(response);

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        return null;
      } else {
        // Handle validation errors
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          return errors.values.first[0] as String;
        }
        return (data['message'] as String?) ?? 'Registrasi gagal';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Koneksi ke server gagal. Periksa jaringan.';
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/logout', {});
    } catch (_) {}
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<String?> updateProfile({
    required String name,
    required String username,
    required String email,
    String? noTelp,
    String? password,
    String? fotoPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fields = <String, String>{
        'name': name,
        'username': username,
        'email': email,
        'no_telp': noTelp ?? '',
      };
      if (password != null && password.isNotEmpty) {
        fields['password'] = password;
        fields['password_confirmation'] = password;
      }

      final responseBody = await _sendUpdateRequest(fields, fotoPath);

      _isLoading = false;

      if (responseBody != null && responseBody['status'] == 'success') {
        _user = UserModel.fromJson(responseBody['data'] as Map<String, dynamic>);
        notifyListeners();
        return null;
      } else {
        notifyListeners();
        if (responseBody?['errors'] != null) {
          final errors = responseBody?['errors'] as Map<String, dynamic>;
          return errors.values.first[0] as String;
        }
        return (responseBody?['message'] as String?) ?? 'Gagal memperbarui profil';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Koneksi ke server gagal';
    }
  }

  Future<Map<String, dynamic>?> _sendUpdateRequest(Map<String, String> fields, String? fotoPath) async {
    if (fotoPath != null) {
      final streamed = await ApiService.postMultipart('/profile/update', fields, filePath: fotoPath, fileField: 'foto');
      return await ApiService.parseStreamedResponse(streamed);
    } else {
      final response = await ApiService.post('/profile/update', fields);
      return ApiService.parseResponse(response);
    }
  }
}
