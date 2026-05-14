const { admin } = require('../firebase');

module.exports = async function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Нэвтрэх шаардлагатай' });
  }
  try {
    req.user = await admin.auth().verifyIdToken(header.slice(7));
    next();
  } catch {
    return res.status(401).json({ error: 'Нэвтрэх эрх хүчингүй байна' });
  }
};
