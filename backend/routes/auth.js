const express = require('express');
const nodemailer = require('nodemailer');
const { db } = require('../firebase');

const router = express.Router();

function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function createTransporter() {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT || '587'),
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
}

// POST /api/auth/send-code
// Body: { email, uid }
router.post('/send-code', async (req, res) => {
  const { email, uid } = req.body;
  if (!email || !uid) {
    return res.status(400).json({ error: 'email, uid шаардлагатай' });
  }

  const code = generateCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 минут

  try {
    await db.collection('email_verifications').doc(uid).set({
      code,
      email,
      expiresAt,
      createdAt: new Date(),
    });

    const transporter = createTransporter();
    await transporter.sendMail({
      from: `"Говийн Спорт" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Говийн Спорт — Баталгаажуулах код',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 420px; margin: 0 auto; padding: 32px 24px; background: #f9fafb; border-radius: 12px;">
          <h2 style="margin: 0 0 8px; color: #1d4ed8; font-size: 22px;">Говийн Спорт 🏀</h2>
          <p style="color: #374151; margin: 0 0 24px;">Таны бүртгэлийн баталгаажуулах код:</p>
          <div style="background: #fff; border: 1px solid #e5e7eb; padding: 24px; border-radius: 10px; text-align: center; margin-bottom: 24px;">
            <span style="font-size: 40px; font-weight: 800; letter-spacing: 10px; color: #1d4ed8;">${code}</span>
          </div>
          <p style="color: #6b7280; font-size: 13px; margin: 0;">Код <strong>10 минутын</strong> дотор хүчинтэй. Та энэ кодыг хэнд ч хэлэх хэрэггүй.</p>
        </div>
      `,
    });

    res.json({ success: true });
  } catch (err) {
    console.error('Код илгээх алдаа:', err.message);
    res.status(500).json({ error: 'Код илгээхэд алдаа гарлаа. Email хаяг зөв эсэхийг шалгана уу' });
  }
});

// POST /api/auth/verify-code
// Body: { uid, code }
router.post('/verify-code', async (req, res) => {
  const { uid, code } = req.body;
  if (!uid || !code) {
    return res.status(400).json({ error: 'uid, code шаардлагатай' });
  }

  try {
    const snap = await db.collection('email_verifications').doc(uid).get();
    if (!snap.exists) {
      return res.status(400).json({ error: 'Код олдсонгүй. Дахин илгээнэ үү' });
    }

    const data = snap.data();
    if (data.code !== code) {
      return res.status(400).json({ error: 'Код буруу байна' });
    }
    if (new Date() > data.expiresAt.toDate()) {
      return res.status(400).json({ error: 'Кодын хугацаа дууссан. Дахин илгээнэ үү' });
    }

    // Хэрэглэгчийг баталгаажуулсан гэж тэмдэглэх
    await db.collection('users').doc(uid).set(
      { emailVerified: true, updatedAt: new Date() },
      { merge: true }
    );

    // Баталгаажуулалтын мэдээллийг устгах
    await db.collection('email_verifications').doc(uid).delete();

    res.json({ success: true });
  } catch (err) {
    console.error('Код шалгах алдаа:', err.message);
    res.status(500).json({ error: 'Серверийн алдаа гарлаа' });
  }
});

module.exports = router;
