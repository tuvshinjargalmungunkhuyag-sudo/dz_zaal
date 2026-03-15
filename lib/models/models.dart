import 'package:flutter/material.dart';

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

  TimeSlot({
    required this.id,
    required this.time,
    required this.endTime,
    this.isBooked = false,
    this.isSelected = false,
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
      name: 'Говийн Аренa',
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
      name: 'Өмнөговь Фитнес',
      type: 'Фитнес',
      location: 'Даланзадгад, 2-р хороо',
      rating: 4.6,
      reviewCount: 89,
      pricePerHour: '10,000₮',
      facilities: ['Тренажер', 'Душ', 'Сейф', 'Тренер'],
      imagePath: 'fitness',
      accentColor: const Color(0xFF7B2FBE),
      isAvailable: true,
    ),
    SportVenue(
      id: '3',
      name: 'Говийн Теннис Клуб',
      type: 'Теннис',
      location: 'Даланзадгад, Голомт',
      rating: 4.7,
      reviewCount: 56,
      pricePerHour: '20,000₮',
      facilities: ['Ракетка', 'Душ', 'Паркинг'],
      imagePath: 'tennis',
      accentColor: const Color(0xFF00E096),
      isAvailable: false,
    ),
    SportVenue(
      id: '4',
      name: 'Хурдан Хөл Бөмбөг',
      type: 'Хөл бөмбөг',
      location: 'Даланзадгад, Стадион',
      rating: 4.5,
      reviewCount: 203,
      pricePerHour: '25,000₮',
      facilities: ['Гардероб', 'Душ', 'Гэрэлтүүлэг', 'Камер'],
      imagePath: 'football',
      accentColor: const Color(0xFFFFB800),
      isAvailable: true,
    ),
    SportVenue(
      id: '5',
      name: 'Говийн Бөхийн Танхим',
      type: 'Бөх',
      location: 'Даланзадгад, 3-р хороо',
      rating: 4.9,
      reviewCount: 67,
      pricePerHour: '12,000₮',
      facilities: ['Матрац', 'Душ', 'Тренер'],
      imagePath: 'wrestling',
      accentColor: const Color(0xFFFF6B6B),
      isAvailable: true,
    ),
  ];

  static List<TimeSlot> generateTimeSlots() {
    final List<TimeSlot> slots = [];
    final List<bool> bookedSlots = [
      false,
      true,
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      false,
      false,
      true,
    ];
    final startHour = 8;

    for (int i = 0; i < 12; i++) {
      final hour = startHour + i;
      final nextHour = hour + 1;
      slots.add(
        TimeSlot(
          id: 'slot_$i',
          time: '${hour.toString().padLeft(2, '0')}:00',
          endTime: '${nextHour.toString().padLeft(2, '0')}:00',
          isBooked: bookedSlots[i],
        ),
      );
    }
    return slots;
  }
}
