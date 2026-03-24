const express = require('express');
const { db } = require('../firebase');

const router = express.Router();
const bookings = db.collection('bookings');

// Заалын гэрээт (fixed) захиалгууд — Firestore-д хадгалагдана
// Эхлэлд seed хийнэ, дараа нь /api/schedule/fixed CRUD ашиглана
const fixedBookings_collection = db.collection('fixed_bookings');

// Тухайн заал + өдрийн хуваарь (бүх слот + захиалгатай эсэх)
// GET /api/schedule?venueId=1&date=2026-03-17
router.get('/', async (req, res) => {
  const { venueId, date } = req.query;
  if (!venueId || !date) {
    return res.status(400).json({ error: 'venueId, date (YYYY-MM-DD) шаардлагатай' });
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'date формат: YYYY-MM-DD' });
  }

  try {
    const dateObj = new Date(date);
    const weekday = dateObj.getDay() === 0 ? 7 : dateObj.getDay(); // 1=Да..7=Ня

    // Гэрээт захиалгуудыг унших
    const fixedSnap = await fixedBookings_collection
      .where('venueId', '==', venueId)
      .where('weekDays', 'array-contains', weekday)
      .get();

    const fixedHours = {};
    fixedSnap.docs.forEach((d) => {
      const { startHour, endHour, organizationName } = d.data();
      for (let h = startHour; h < endHour; h++) {
        fixedHours[h] = organizationName;
      }
    });

    // Захиалагдсан цагуудыг унших
    const bookedSnap = await bookings
      .where('venueId', '==', venueId)
      .where('dateKey', '==', date)
      .where('status', 'in', ['upcoming', 'active'])
      .get();

    // Слот бүрийн захиалгын мэдээлэл: хагас/бүтэн талбай
    const slotMap = {};
    bookedSnap.docs.forEach((d) => {
      const { timeSlot, courtType } = d.data();
      if (!slotMap[timeSlot]) slotMap[timeSlot] = { halfCourtCount: 0, hasFullCourt: false };
      if (courtType === 'Хагас талбай') {
        slotMap[timeSlot].halfCourtCount++;
      } else {
        slotMap[timeSlot].hasFullCourt = true;
      }
    });

    // 08:00–20:00 нийт 12 слот үүсгэх
    const slots = [];
    for (let hour = 8; hour < 20; hour++) {
      const time = `${String(hour).padStart(2, '0')}:00`;
      const endTime = `${String(hour + 1).padStart(2, '0')}:00`;
      const isFixed = hour in fixedHours;
      const info = slotMap[time] || { halfCourtCount: 0, hasFullCourt: false };
      const isFullyBooked = info.hasFullCourt || info.halfCourtCount >= 2;
      slots.push({
        time,
        endTime,
        isBooked: isFixed || isFullyBooked,
        isFixed,
        fixedBy: fixedHours[hour] || null,
        halfCourtCount: info.halfCourtCount,
        hasFullCourt: info.hasFullCourt,
      });
    }

    res.json({ venueId, date, weekday, slots });
  } catch (err) {
    console.error('Schedule алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

// Гэрээт захиалга нэмэх
// POST /api/schedule/fixed
// Body: { venueId, organizationName, weekDays: [1,3], startHour: 9, endHour: 11 }
router.post('/fixed', async (req, res) => {
  const { venueId, organizationName, weekDays, startHour, endHour } = req.body;

  if (!venueId || !organizationName || !weekDays || startHour == null || endHour == null) {
    return res.status(400).json({ error: 'venueId, organizationName, weekDays, startHour, endHour шаардлагатай' });
  }
  if (!Array.isArray(weekDays) || weekDays.some((d) => d < 1 || d > 7)) {
    return res.status(400).json({ error: 'weekDays: 1–7 (1=Да, 7=Ня) массив байх ёстой' });
  }
  if (startHour >= endHour || startHour < 8 || endHour > 20) {
    return res.status(400).json({ error: 'startHour/endHour: 8–20 хооронд байх ёстой' });
  }

  try {
    const doc = await fixedBookings_collection.add({
      venueId,
      organizationName,
      weekDays,
      startHour,
      endHour,
      createdAt: new Date(),
    });
    res.status(201).json({ id: doc.id });
  } catch (err) {
    console.error('Fixed booking алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

// Гэрээт захиалга устгах
// DELETE /api/schedule/fixed/:id
router.delete('/fixed/:id', async (req, res) => {
  try {
    const ref = fixedBookings_collection.doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'Гэрээт захиалга олдсонгүй' });
    }
    await ref.delete();
    res.json({ success: true });
  } catch (err) {
    console.error('Fixed booking алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

module.exports = router;
