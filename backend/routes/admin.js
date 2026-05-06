const express = require('express');
const { db } = require('../firebase');

const router = express.Router();

// Simple admin key middleware
router.use((req, res, next) => {
  const key = req.headers['x-admin-key'];
  if (!key || key !== process.env.ADMIN_KEY) {
    return res.status(401).json({ error: 'Admin эрх байхгүй' });
  }
  next();
});

const bookings = db.collection('bookings');
const users    = db.collection('users');

// GET /api/admin/stats
router.get('/stats', async (req, res) => {
  try {
    const snap = await bookings.get();
    const all  = snap.docs.map((d) => d.data());

    const today = new Date().toISOString().slice(0, 10);

    const stats = {
      total:     all.length,
      upcoming:  all.filter((b) => b.status === 'upcoming').length,
      active:    all.filter((b) => b.status === 'active').length,
      completed: all.filter((b) => b.status === 'completed').length,
      cancelled: all.filter((b) => b.status === 'cancelled').length,
      today:     all.filter((b) => b.dateKey === today).length,
      todayRevenue: all
        .filter((b) => b.dateKey === today && b.status !== 'cancelled' && b.isGroupLeader !== false)
        .reduce((sum, b) => {
          const p = parseInt((b.price || '').replace(/[^\d]/g, '')) || 0;
          return sum + p;
        }, 0),
      totalRevenue: all
        .filter((b) => b.status !== 'cancelled' && b.isGroupLeader !== false)
        .reduce((sum, b) => {
          const p = parseInt((b.price || '').replace(/[^\d]/g, '')) || 0;
          return sum + p;
        }, 0),
    };

    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/admin/bookings?status=&venueId=&date=&limit=50
router.get('/bookings', async (req, res) => {
  try {
    const { status, venueId, date } = req.query;
    let query = bookings.orderBy('createdAt', 'desc');

    if (status)  query = query.where('status', '==', status);
    if (venueId) query = query.where('venueId', '==', venueId);
    if (date)    query = query.where('dateKey', '==', date);

    const snap = await query.limit(200).get();
    const result = snap.docs
      .map((d) => ({ id: d.id, ...d.data(), createdAt: d.data().createdAt?.toDate?.()?.toISOString() }))
      .filter((b) => b.groupId == null || b.isGroupLeader === true);

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /api/admin/bookings/:id/status
// Body: { status: 'upcoming' | 'active' | 'completed' | 'cancelled' }
router.patch('/bookings/:id/status', async (req, res) => {
  const { status } = req.body;
  const allowed = ['upcoming', 'active', 'completed', 'cancelled'];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: 'Буруу статус' });
  }

  try {
    const ref  = bookings.doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'Захиалга олдсонгүй' });

    const { groupId } = snap.data();
    if (groupId) {
      const groupSnap = await bookings.where('groupId', '==', groupId).get();
      const batch = db.batch();
      groupSnap.docs.forEach((d) => batch.update(d.ref, { status, updatedAt: new Date() }));
      await batch.commit();
    } else {
      await ref.update({ status, updatedAt: new Date() });
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/admin/bookings  — гараар захиалга үүсгэх
router.post('/bookings', async (req, res) => {
  const { userEmail, userName, venueId, venueName, dateKey, startTime, endTime, price, courtType } = req.body;
  if (!userEmail || !venueId || !dateKey || !startTime || !endTime) {
    return res.status(400).json({ error: 'userEmail, venueId, dateKey, startTime, endTime шаардлагатай' });
  }
  try {
    const ref = await bookings.add({
      userEmail,
      userName:  userName  || '',
      venueId,
      venueName: venueName || venueId,
      dateKey,
      startTime,
      endTime,
      timeSlot:  `${startTime}–${endTime}`,
      price:     price     || '0₮',
      courtType: courtType || '',
      status:    'upcoming',
      createdByAdmin: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    res.json({ id: ref.id, success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/admin/chart?days=14  — өдрийн захиалга/орлогын нэгдсэн өгөгдөл
router.get('/chart', async (req, res) => {
  const days = Math.min(parseInt(req.query.days) || 14, 90);
  try {
    const snap = await bookings.get();
    const all  = snap.docs.map((d) => d.data());

    const result = [];
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateKey = d.toISOString().slice(0, 10);
      const dayBookings = all.filter((b) => b.dateKey === dateKey && b.isGroupLeader !== false);
      const revenue = dayBookings
        .filter((b) => b.status !== 'cancelled')
        .reduce((s, b) => s + (parseInt((b.price || '').replace(/[^\d]/g, '')) || 0), 0);
      result.push({ date: dateKey, count: dayBookings.length, revenue });
    }
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/admin/users
router.get('/users', async (req, res) => {
  try {
    const snap = await users.orderBy('createdAt', 'desc').limit(200).get();
    const result = snap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
      createdAt: d.data().createdAt?.toDate?.()?.toISOString(),
    }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
