import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class ApiService {
  static String? currentUserName;

  // Сүлжээ удаашрах эсвэл тасрах үед UI хязгааргүй хүлээхээс сэргийлэх
  static const _timeout = Duration(seconds: 15);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Хэрэглэгч ─────────────────────────────────────────────────────────────

  static Future<void> registerUser({
    required String name,
    required String email,
  }) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.usersEndpoint),
          headers: _headers,
          body: jsonEncode({'name': name, 'email': email, 'uid': _currentUid()}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_error(res));
    }
    currentUserName = name;
  }

  static String _currentUid() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) throw Exception('Нэвтрээгүй байна');
    return uid;
  }

  // ── Захиалга ───────────────────────────────────────────────────────────────

  static Future<({String id, String code})> createBooking({
    required String venueId,
    required String venueName,
    required String venueType,
    required String venueLocation,
    required int venueAccentColor,
    required DateTime date,
    required String timeSlot,
    required String timeSlotEnd,
    required String courtType,
    required String price,
    required String userName,
    required String userEmail,
  }) async {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final res = await http
        .post(
          Uri.parse(AppConfig.bookingsEndpoint),
          headers: _headers,
          body: jsonEncode({
            'venueId': venueId,
            'venueName': venueName,
            'venueType': venueType,
            'venueLocation': venueLocation,
            'venueAccentColor': venueAccentColor,
            'date': dateKey,
            'timeSlot': timeSlot,
            'timeSlotEnd': timeSlotEnd,
            'courtType': courtType,
            'price': price,
            'userName': userName,
            'userEmail': userEmail,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 409) {
      throw Exception('Тухайн цаг аль хэдийн захиалагдсан байна');
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_error(res));
    }

    final body = jsonDecode(res.body);
    return (id: body['id'] as String, code: body['code'] as String);
  }

  static Future<void> cancelBooking(String bookingId) async {
    final res = await http
        .delete(
          Uri.parse('${AppConfig.bookingsEndpoint}/$bookingId'),
          headers: _headers,
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception(_error(res));
    }
  }

  // ── Хуваарь ────────────────────────────────────────────────────────────────

  static Future<List<TimeSlot>> getSchedule(
      String venueId, DateTime date) async {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(AppConfig.scheduleEndpoint)
        .replace(queryParameters: {'venueId': venueId, 'date': dateKey});

    final res = await http.get(uri, headers: _headers).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception(_error(res));
    }

    final slots = jsonDecode(res.body)['slots'] as List<dynamic>;
    return slots.asMap().entries.map((e) {
      final s = e.value as Map<String, dynamic>;
      return TimeSlot(
        id: 'slot_${e.key}',
        time: s['time'] as String,
        endTime: s['endTime'] as String,
        isBooked: s['isBooked'] as bool,
        isFixed: s['isFixed'] as bool,
        fixedBy: s['fixedBy'] as String?,
        halfCourtCount: (s['halfCourtCount'] as int?) ?? 0,
        hasFullCourt: (s['hasFullCourt'] as bool?) ?? false,
      );
    }).toList();
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  static String _error(http.Response res) {
    try {
      return jsonDecode(res.body)['error'] ?? 'Серверийн алдаа (${res.statusCode})';
    } catch (_) {
      return 'Серверийн алдаа (${res.statusCode})';
    }
  }
}
