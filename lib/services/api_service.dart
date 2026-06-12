import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: await _headers(),
    );
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    return http.post(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path, {bool auth = true}) async {
    return http.delete(
      Uri.parse('${AppConfig.baseUrl}$path'),
      headers: await _headers(auth: auth),
    );
  }

  static Future<http.StreamedResponse> postMultipart(
    String path,
    Map<String, String> fields, {
    String? filePath,
    String fileField = 'foto',
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}$path'));
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    return request.send();
  }

  static Map<String, dynamic> parseResponse(http.Response response) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> parseStreamedResponse(http.StreamedResponse streamed) async {
    final body = await streamed.stream.bytesToString();
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
