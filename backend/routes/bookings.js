const express = require('express');
const { db } = require('../firebase');

const router = express.Router();
const bookings = db.collection('bookings');

// POST /api/bookings
// Body: { venueId, venueName, venueType, venueLocation, venueAccentColor,
//         date (YYYY-MM-DD), timeSlots: ["09:00","10:00","11:00"], timeSlotEnd,
//         courtType, price, userName, userEmail }
router.post('/', async (req, res) => {
  const {
    venueId, venueName, venueType, venueLocation, venueAccentColor,
    date, timeSlots, timeSlotEnd, courtType, price, userName, userEmail,
  } = req.body;

  const required = { venueId, venueName, date, timeSlots, timeSlotEnd, userName, userEmail };
  const missing = Object.keys(required).filter((k) => !required[k]);
  if (missing.length) {
    return res.status(400).json({ error: `Дутуу талбар: ${missing.join(', ')}` });
  }
  if (!Array.isArray(timeSlots) || timeSlots.length === 0) {
    return res.status(400).json({ error: 'timeSlots хоосон байж болохгүй' });
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'date формат: YYYY-MM-DD' });
  }

  try {
    // Conflict check for every selected slot
    for (const slot of timeSlots) {
      const existingSnap = await bookings
        .where('venueId', '==', venueId)
        .where('dateKey', '==', date)
        .where('timeSlot', '==', slot)
        .where('status', 'in', ['upcoming', 'active'])
        .get();

      if (!existingSnap.empty) {
        if (courtType !== 'Хагас талбай') {
          return res.status(409).json({ error: `${slot} цаг аль хэдийн захиалагдсан байна` });
        }
        const hasFullCourt = existingSnap.docs.some((d) => d.data().courtType !== 'Хагас талбай');
        if (hasFullCourt) {
          return res.status(409).json({ error: `${slot} цаг бүтэн талбайгаар захиалагдсан байна` });
        }
        const halfCount = existingSnap.docs.filter((d) => d.data().courtType === 'Хагас талбай').length;
        if (halfCount >= 2) {
          return res.status(409).json({ error: `${slot} цаг аль хэдийн 2 хагас талбайгаар захиалагдсан байна` });
        }
      }
    }

    const code = `DBK-${Date.now() % 100000}`;
    const groupId = timeSlots.length > 1 ? `GRP-${Date.now()}` : null;
    const displayTimeSlot = timeSlots[0];
    const displayTimeSlotEnd = timeSlotEnd;

    const batch = db.batch();
    const firstRef = bookings.doc();

    timeSlots.forEach((slot, idx) => {
      const ref = idx === 0 ? firstRef : bookings.doc();
      const slotEndTime = timeSlots[idx + 1] || timeSlotEnd;
      const docData = {
        venueId,
        venueName,
        venueType: venueType || '',
        venueLocation: venueLocation || '',
        venueAccentColor: venueAccentColor || 0,
        dateKey: date,
        date: new Date(date),
        timeSlot: slot,
        timeSlotEnd: slotEndTime,
        displayTimeSlot,
        displayTimeSlotEnd,
        courtType: courtType || '',
        price: price || '',
        userName,
        userEmail,
        status: 'upcoming',
        code,
        createdAt: new Date(),
      };
      if (groupId) {
        docData.groupId = groupId;
        docData.isGroupLeader = idx === 0;
      }
      batch.set(ref, docData);
    });

    await batch.commit();
    res.status(201).json({ id: firstRef.id, code });
  } catch (err) {
    console.error('Bookings алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

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

// DELETE /api/bookings/:id — single doc эсвэл groupId-ийн бүх docуудыг цуцлах
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

    const { groupId } = snap.data();
    const now = new Date();

    if (groupId) {
      const groupSnap = await bookings
        .where('groupId', '==', groupId)
        .where('status', 'in', ['upcoming', 'active'])
        .get();
      const batch = db.batch();
      groupSnap.docs.forEach((d) => batch.update(d.ref, { status: 'cancelled', cancelledAt: now }));
      await batch.commit();
    } else {
      await ref.update({ status: 'cancelled', cancelledAt: now });
    }

    res.json({ success: true });
  } catch (err) {
    console.error('Bookings алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

module.exports = router;
