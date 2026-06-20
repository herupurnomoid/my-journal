import 'dart:convert';
import 'package:http/http.dart' as http;

class PinApiService {
  static const String baseUrl = 'https://asia-southeast2-my-journal-8c171.cloudfunctions.net/api/v1';

  Future<String> forgotPin(String email) async {
    final url = Uri.parse('$baseUrl/auth/pin/forgot');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['data'] ?? 'OTP berhasil dikirim';
    } else {
      throw Exception('Gagal mengirim OTP: ${response.statusCode}');
    }
  }

  Future<String> verifyOtp(String email, String otpCode) async {
    final url = Uri.parse('$baseUrl/auth/pin/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otpCode': otpCode,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      // Backend returns: { "data": { "resetToken": "..." } }
      final responseData = data['data'];
      if (responseData != null && responseData['resetToken'] != null) {
        return responseData['resetToken'];
      }
      throw Exception('Token reset tidak ditemukan dalam respons');
    } else {
      throw Exception('OTP tidak valid atau kadaluarsa');
    }
  }
}
