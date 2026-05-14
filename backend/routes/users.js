const express = require('express');
const { db } = require('../firebase');
const requireAuth = require('../middleware/auth');

const router = express.Router();
const users = db.collection('users');

// Хэрэглэгч бүртгэх / шинэчлэх (uid-аар upsert)
// POST /api/users
// Body: { name, email, uid }
router.post('/', requireAuth, async (req, res) => {
  const { name, email, uid } = req.body;
  if (!name || !email || !uid) {
    return res.status(400).json({ error: 'name, email, uid шаардлагатай' });
  }

  try {
    const ref = users.doc(uid);
    const snap = await ref.get();

    if (snap.exists) {
      await ref.update({ name, updatedAt: new Date() });
      return res.json({ id: uid, ...snap.data(), name });
    }

    const user = {
      name,
      email,
      uid,
      emailVerified: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    await ref.set(user);
    res.status(201).json({ id: uid, ...user });
  } catch (err) {
    console.error('Users алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

// Хэрэглэгч унших
// GET /api/users/:uid
router.get('/:uid', async (req, res) => {
  try {
    const snap = await users.doc(req.params.uid).get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'Хэрэглэгч олдсонгүй' });
    }
    res.json({ id: req.params.uid, ...snap.data() });
  } catch (err) {
    console.error('Users алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

module.exports = router;
