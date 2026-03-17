const admin = require('firebase-admin');

if (!admin.apps.length) {
  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT_B64) {
    // DigitalOcean: base64 encoded JSON
    const json = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_B64, 'base64').toString('utf8');
    credential = admin.credential.cert(JSON.parse(json));
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Local .env: JSON string
    credential = admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT));
  } else {
    // DigitalOcean fallback: тусдаа env var-уудаас
    const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');
    credential = admin.credential.cert({
      projectId:   process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey,
    });
  }

  admin.initializeApp({ credential });
}

const db = admin.firestore();
module.exports = { db };
