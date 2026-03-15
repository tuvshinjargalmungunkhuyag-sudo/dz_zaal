import 'package:flutter/material.dart';

enum AppNotificationType { booking, reminder, promo, system }

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });
}

class SportVenue {
  final String id;
  final String name;
  final String type;
  final String location;
  final double rating;
  final int reviewCount;
  final String pricePerHour;
  final List<String> facilities;
  final String imagePath;
  final Color accentColor;
  final bool isAvailable;

  SportVenue({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.pricePerHour,
    required this.facilities,
    required this.imagePath,
    required this.accentColor,
    this.isAvailable = true,
  });
}

class TimeSlot {
  final String id;
  final String time;
  final String endTime;
  bool isBooked;
  bool isSelected;
  final bool isFixed;
  final String? fixedBy;

  TimeSlot({
    required this.id,
    required this.time,
    required this.endTime,
    this.isBooked = false,
    this.isSelected = false,
    this.isFixed = false,
    this.fixedBy,
  });
}

class FixedBooking {
  final String venueId;
  final String organizationName;
  final List<int> weekDays; // 1=Да, 2=Мя, 3=Лх, 4=Пү, 5=Ба, 6=Бя, 7=Ня
  final int startHour;
  final int endHour;

  const FixedBooking({
    required this.venueId,
    required this.organizationName,
    required this.weekDays,
    required this.startHour,
    required this.endHour,
  });
}

class Booking {
  final String id;
  final SportVenue venue;
  final DateTime date;
  final TimeSlot timeSlot;
  final String userName;
  final String status;

  Booking({
    required this.id,
    required this.venue,
    required this.date,
    required this.timeSlot,
    required this.userName,
    required this.status,
  });
}

// Sample Data
class AppData {
  static List<SportVenue> venues = [
    SportVenue(
      id: '1',
      name: 'Говийн Арена',
      type: 'Сагсан бөмбөг',
      location: 'Даланзадгад, 1-р хороо',
      rating: 4.8,
      reviewCount: 124,
      pricePerHour: '15,000₮',
      facilities: ['Гардероб', 'Душ', 'Паркинг', 'WiFi'],
      imagePath: 'basketball',
      accentColor: const Color(0xFF00D4FF),
      isAvailable: true,
    ),
    SportVenue(
      id: '2',
      name: 'Өмнөговь Спорт Заал',
      type: 'Сагсан бөмбөг',
      location: 'Даланзадгад, 2-р хороо',
      rating: 4.6,
      reviewCount: 89,
      pricePerHour: '12,000₮',
      facilities: ['Гардероб', 'Душ', 'WiFi'],
      imagePath: 'basketball',
      accentColor: const Color(0xFF00D4FF),
      isAvailable: true,
    ),
    SportVenue(
      id: '3',
      name: 'Говийн Волейбол Клуб',
      type: 'Волейбол',
      location: 'Даланзадгад, Голомт',
      rating: 4.7,
      reviewCount: 56,
      pricePerHour: '10,000₮',
      facilities: ['Гардероб', 'Душ', 'Паркинг'],
      imagePath: 'volleyball',
      accentColor: const Color(0xFFFFB800),
      isAvailable: true,
    ),
    SportVenue(
      id: '4',
      name: 'Стадионы Волейбол Заал',
      type: 'Волейбол',
      location: 'Даланзадгад, Стадион',
      rating: 4.5,
      reviewCount: 203,
      pricePerHour: '8,000₮',
      facilities: ['Гардероб', 'Душ', 'Гэрэлтүүлэг', 'Камер'],
      imagePath: 'volleyball',
      accentColor: const Color(0xFFFFB800),
      isAvailable: false,
    ),
    SportVenue(
      id: '5',
      name: 'Цэнтрийн Сагсан Бөмбөгийн Заал',
      type: 'Сагсан бөмбөг',
      location: 'Даланзадгад, 3-р хороо',
      rating: 4.9,
      reviewCount: 67,
      pricePerHour: '18,000₮',
      facilities: ['Гардероб', 'Душ', 'Тренер', 'WiFi'],
      imagePath: 'basketball',
      accentColor: const Color(0xFF00D4FF),
      isAvailable: true,
    ),
  ];

  static const List<FixedBooking> fixedBookings = [
    FixedBooking(
      venueId: '1',
      organizationName: 'Аймгийн Засаг Дарга',
      weekDays: [1, 3], // Даваа, Лхагва
      startHour: 9,
      endHour: 11,
    ),
    FixedBooking(
      venueId: '1',
      organizationName: 'Аймгийн Засаг Дарга',
      weekDays: [5], // Баасан
      startHour: 10,
      endHour: 12,
    ),
    FixedBooking(
      venueId: '3',
      organizationName: 'ӨМААГ',
      weekDays: [2, 4], // Мягмар, Пүрэв
      startHour: 14,
      endHour: 16,
    ),
    FixedBooking(
      venueId: '5',
      organizationName: 'Даланзадгад хотын ИТХ',
      weekDays: [1, 2, 3, 4, 5], // Ажлын өдрүүд
      startHour: 8,
      endHour: 10,
    ),
  ];

  static List<TimeSlot> generateTimeSlots(String venueId, DateTime date) {
    // Тухайн заалд тухайн өдрийн гэрээт цагуудыг тодорхойлно
    final fixedHours = <int, String>{};
    for (final fb in fixedBookings) {
      if (fb.venueId == venueId && fb.weekDays.contains(date.weekday)) {
        for (int h = fb.startHour; h < fb.endHour; h++) {
          fixedHours[h] = fb.organizationName;
        }
      }
    }

    const bookedPattern = [false, true, false, false, true, false, false, true, false, false, false, true];
    const startHour = 8;
    final List<TimeSlot> slots = [];

    for (int i = 0; i < 12; i++) {
      final hour = startHour + i;
      final isFixed = fixedHours.containsKey(hour);
      slots.add(
        TimeSlot(
          id: 'slot_$i',
          time: '${hour.toString().padLeft(2, '0')}:00',
          endTime: '${(hour + 1).toString().padLeft(2, '0')}:00',
          isBooked: isFixed ? true : bookedPattern[i],
          isFixed: isFixed,
          fixedBy: fixedHours[hour],
        ),
      );
    }
    return slots;
  }
}
