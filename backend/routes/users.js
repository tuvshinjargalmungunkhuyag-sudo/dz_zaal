const express = require('express');
const { db } = require('../firebase');

const router = express.Router();
const users = db.collection('users');

// Хэрэглэгч бүртгэх / шинэчлэх (утасны дугаараар upsert)
// POST /api/users
// Body: { name, phone }
router.post('/', async (req, res) => {
  const { name, phone } = req.body;
  if (!name || !phone) {
    return res.status(400).json({ error: 'name, phone шаардлагатай' });
  }

  const phone_clean = phone.replace(/\D/g, '');
  if (phone_clean.length < 8) {
    return res.status(400).json({ error: 'Утасны дугаар буруу байна' });
  }

  try {
    const ref = users.doc(phone_clean);
    const snap = await ref.get();

    if (snap.exists) {
      await ref.update({ name, updatedAt: new Date() });
      return res.json({ id: phone_clean, ...snap.data(), name });
    }

    const user = {
      name,
      phone: phone_clean,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    await ref.set(user);
    res.status(201).json({ id: phone_clean, ...user });
  } catch (err) {
    console.error('Users алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

// Хэрэглэгч унших
// GET /api/users/:phone
router.get('/:phone', async (req, res) => {
  const phone_clean = req.params.phone.replace(/\D/g, '');
  try {
    const snap = await users.doc(phone_clean).get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'Хэрэглэгч олдсонгүй' });
    }
    res.json({ id: phone_clean, ...snap.data() });
  } catch (err) {
    console.error('Users алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

module.exports = router;
