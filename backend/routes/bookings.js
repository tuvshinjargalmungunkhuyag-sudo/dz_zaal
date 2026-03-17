const express = require('express');
const { db } = require('../firebase');

const router = express.Router();
const bookings = db.collection('bookings');

// Захиалга үүсгэх (давхцал шалгаад хадгална)
// POST /api/bookings
// Body: { venueId, venueName, venueType, venueLocation, venueAccentColor,
//         date (YYYY-MM-DD), timeSlot, timeSlotEnd, courtType, price,
//         userName, userPhone }
router.post('/', async (req, res) => {
  const {
    venueId, venueName, venueType, venueLocation, venueAccentColor,
    date, timeSlot, timeSlotEnd, courtType, price, userName, userPhone,
  } = req.body;

  const required = { venueId, venueName, date, timeSlot, timeSlotEnd, userName, userPhone };
  const missing = Object.keys(required).filter((k) => !required[k]);
  if (missing.length) {
    return res.status(400).json({ error: `Дутуу талбар: ${missing.join(', ')}` });
  }

  // dateKey формат шалгах
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'date формат: YYYY-MM-DD' });
  }

  try {
    // Давхцал шалгах: тухайн заал + өдөр + цаг аль хэдийн захиалагдсан эсэх
    const conflict = await bookings
      .where('venueId', '==', venueId)
      .where('dateKey', '==', date)
      .where('timeSlot', '==', timeSlot)
      .where('status', 'in', ['upcoming', 'active'])
      .get();

    if (!conflict.empty) {
      return res.status(409).json({ error: 'Тухайн цаг аль хэдийн захиалагдсан байна' });
    }

    const code = `DBK-${Date.now() % 100000}`;
    const doc = await bookings.add({
      venueId,
      venueName,
      venueType: venueType || '',
      venueLocation: venueLocation || '',
      venueAccentColor: venueAccentColor || 0,
      dateKey: date,
      date: new Date(date),
      timeSlot,
      timeSlotEnd,
      courtType: courtType || '',
      price: price || '',
      userName,
      userPhone,
      status: 'upcoming',
      code,
      createdAt: new Date(),
    });

    res.status(201).json({ id: doc.id, code });
  } catch (err) {
    console.error('Bookings алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

// Хэрэглэгчийн захиалгуудыг унших
// GET /api/bookings?phone=88001234
router.get('/', async (req, res) => {
  const { phone } = req.query;
  if (!phone) {
    return res.status(400).json({ error: 'phone query шаардлагатай' });
  }

  try {
    const snap = await bookings
      .where('userPhone', '==', phone.replace(/\D/g, ''))
      .orderBy('createdAt', 'desc')
      .get();

    const result = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    res.json(result);
  } catch (err) {
    console.error('Bookings алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

// Захиалга цуцлах
// DELETE /api/bookings/:id
router.delete('/:id', async (req, res) => {
  try {
    const ref = bookings.doc(req.params.id);
    const snap = await ref.get();

    if (!snap.exists) {
      return res.status(404).json({ error: 'Захиалга олдсонгүй' });
    }
    if (snap.data().status === 'cancelled') {
      return res.status(400).json({ error: 'Захиалга аль хэдийн цуцлагдсан байна' });
    }

    await ref.update({ status: 'cancelled', cancelledAt: new Date() });
    res.json({ success: true });
  } catch (err) {
    console.error('Bookings алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

module.exports = router;
