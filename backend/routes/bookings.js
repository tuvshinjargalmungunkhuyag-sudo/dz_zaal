const express = require('express');
const { db } = require('../firebase');
const requireAuth = require('../middleware/auth');

const router = express.Router();
const bookings = db.collection('bookings');
const venueSlots = db.collection('venue_slots');

function slotDocRef(venueId, dateKey, slot) {
  return venueSlots.doc(`${venueId}_${dateKey}_${slot}`);
}

// POST /api/bookings
router.post('/', requireAuth, async (req, res) => {
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

  const code = `DBK-${Date.now() % 100000}`;
  const groupId = timeSlots.length > 1 ? `GRP-${Date.now()}` : null;
  const displayTimeSlot = timeSlots[0];
  const displayTimeSlotEnd = timeSlotEnd;
  const firstRef = bookings.doc();
  const bookingRefs = timeSlots.map((_, idx) => (idx === 0 ? firstRef : bookings.doc()));
  const slotRefs = timeSlots.map((slot) => slotDocRef(venueId, date, slot));

  try {
    await db.runTransaction(async (t) => {
      // Бүх slot-ийн availability-г нэгэн зэрэг, atomic-аар уншина
      const slotSnaps = await Promise.all(slotRefs.map((r) => t.get(r)));

      // Conflict шалгах
      for (let i = 0; i < timeSlots.length; i++) {
        const slot = timeSlots[i];
        const d = slotSnaps[i].data() || { fullBooked: false, halfCount: 0 };

        if (courtType !== 'Хагас талбай') {
          if (d.fullBooked || d.halfCount > 0) {
            const err = new Error(`${slot} цаг аль хэдийн захиалагдсан байна`);
            err.httpCode = 409;
            throw err;
          }
          t.set(slotRefs[i], { fullBooked: true, halfCount: 0, venueId, dateKey: date });
        } else {
          if (d.fullBooked || d.halfCount >= 2) {
            const err = new Error(`${slot} цаг аль хэдийн захиалагдсан байна`);
            err.httpCode = 409;
            throw err;
          }
          t.set(slotRefs[i], {
            fullBooked: false,
            halfCount: (d.halfCount || 0) + 1,
            venueId,
            dateKey: date,
          });
        }
      }

      // Захиалгын document үүсгэх
      timeSlots.forEach((slot, idx) => {
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
        t.set(bookingRefs[idx], docData);
      });
    });

    res.status(201).json({ id: firstRef.id, code });
  } catch (err) {
    if (err.httpCode === 409) {
      return res.status(409).json({ error: err.message });
    }
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

// DELETE /api/bookings/:id — цуцлах + venue_slots шинэчлэх
router.delete('/:id', requireAuth, async (req, res) => {
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

    let docsToCancel;
    if (groupId) {
      const groupSnap = await bookings
        .where('groupId', '==', groupId)
        .where('status', 'in', ['upcoming', 'active'])
        .get();
      docsToCancel = groupSnap.docs;
    } else {
      docsToCancel = [snap];
    }

    await db.runTransaction(async (t) => {
      const slotInfos = docsToCancel.map((d) => {
        const { venueId, dateKey, timeSlot, courtType } = d.data();
        return { ref: slotDocRef(venueId, dateKey, timeSlot), courtType };
      });

      const slotSnaps = await Promise.all(slotInfos.map(({ ref: sr }) => t.get(sr)));

      slotInfos.forEach(({ ref: sr, courtType }, i) => {
        if (!slotSnaps[i].exists) return;
        const d = slotSnaps[i].data();
        if (courtType === 'Хагас талбай') {
          t.update(sr, { halfCount: Math.max(0, (d.halfCount || 1) - 1) });
        } else {
          t.update(sr, { fullBooked: false });
        }
      });

      docsToCancel.forEach((d) => t.update(d.ref, { status: 'cancelled', cancelledAt: now }));
    });

    res.json({ success: true });
  } catch (err) {
    console.error('Bookings алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

module.exports = router;
