import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UploadService {
  static const String baseUrl = "http://https://deskreserve.onrender.com/api";

  static Future<String> uploadIdProof(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/upload/id-proof"),
    );

    request.headers.addAll({
      if (token != null) "Authorization": "Bearer $token",
    });

    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception("ID upload failed");
    }

    final decoded = jsonDecode(response.body);
    return decoded["url"]; // 🔥 EXACTLY what backend returns
  }
}
