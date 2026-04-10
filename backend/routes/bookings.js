const express = require('express');
const { db } = require('../firebase');

const router = express.Router();
const bookings = db.collection('bookings');

// Захиалга үүсгэх (давхцал шалгаад хадгална)
// POST /api/bookings
// Body: { venueId, venueName, venueType, venueLocation, venueAccentColor,
//         date (YYYY-MM-DD), timeSlot, timeSlotEnd, courtType, price,
//         userName, userEmail }
router.post('/', async (req, res) => {
  const {
    venueId, venueName, venueType, venueLocation, venueAccentColor,
    date, timeSlot, timeSlotEnd, courtType, price, userName, userEmail,
  } = req.body;

  const required = { venueId, venueName, date, timeSlot, timeSlotEnd, userName, userEmail };
  const missing = Object.keys(required).filter((k) => !required[k]);
  if (missing.length) {
    return res.status(400).json({ error: `Дутуу талбар: ${missing.join(', ')}` });
  }

  // dateKey формат шалгах
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'date формат: YYYY-MM-DD' });
  }

  try {
    // Давхцал шалгах — талбайн төрлийг харгалзана
    const existingSnap = await bookings
      .where('venueId', '==', venueId)
      .where('dateKey', '==', date)
      .where('timeSlot', '==', timeSlot)
      .where('status', 'in', ['upcoming', 'active'])
      .get();

    if (!existingSnap.empty) {
      if (courtType !== 'Хагас талбай') {
        // Бүтэн талбай авахад ямар ч захиалга байвал болохгүй
        return res.status(409).json({ error: 'Тухайн цаг аль хэдийн захиалагдсан байна' });
      }
      // Хагас талбай: бүтэн талбай байвал болохгүй, 2 хагас байвал болохгүй
      const hasFullCourt = existingSnap.docs.some((d) => d.data().courtType !== 'Хагас талбай');
      if (hasFullCourt) {
        return res.status(409).json({ error: 'Тухайн цаг бүтэн талбайгаар захиалагдсан байна' });
      }
      const halfCount = existingSnap.docs.filter((d) => d.data().courtType === 'Хагас талбай').length;
      if (halfCount >= 2) {
        return res.status(409).json({ error: 'Тухайн цаг аль хэдийн 2 хагас талбайгаар захиалагдсан байна' });
      }
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
      userEmail,
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
// GET /api/bookings?email=user@example.com
router.get('/', async (req, res) => {
  const { email } = req.query;
  if (!email) {
    return res.status(400).json({ error: 'email query шаардлагатай' });
  }

  try {
    const snap = await bookings
      .where('userEmail', '==', email)
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
