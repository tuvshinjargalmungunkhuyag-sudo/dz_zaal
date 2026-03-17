import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static final _bookings = _db.collection('bookings');

  // Захиалга хадгалах
  static Future<String> saveBooking({
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
    required String userPhone,
  }) async {
    final code = 'DBK-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final doc = await _bookings.add({
      'venueId': venueId,
      'venueName': venueName,
      'venueType': venueType,
      'venueLocation': venueLocation,
      'venueAccentColor': venueAccentColor,
      'date': Timestamp.fromDate(date),
      'dateKey': dateKey,
      'timeSlot': timeSlot,
      'timeSlotEnd': timeSlotEnd,
      'courtType': courtType,
      'price': price,
      'userName': userName,
      'userPhone': userPhone,
      'status': 'upcoming',
      'code': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Хэрэглэгчийн захиалгуудыг унших (real-time)
  static Stream<List<Map<String, dynamic>>> getUserBookings(String userName) {
    return _bookings
        .where('userName', isEqualTo: userName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  // Тухайн заал, өдрийн захиалагдсан цагуудыг унших
  static Future<List<String>> getBookedSlots(
      String venueId, DateTime date) async {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final snap = await _bookings
        .where('venueId', isEqualTo: venueId)
        .where('dateKey', isEqualTo: dateKey)
        .where('status', whereIn: ['upcoming', 'active']).get();
    return snap.docs.map((d) => d['timeSlot'] as String).toList();
  }

  // Захиалга цуцлах
  static Future<void> cancelBooking(String bookingId) async {
    await _bookings.doc(bookingId).update({'status': 'cancelled'});
  }
}
