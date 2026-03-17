const { db } = require('./firebase');

// Монголын цагийн бүс: UTC+8
function nowMongolia() {
  return new Date(Date.now() + 8 * 60 * 60 * 1000);
}

// "09:00" → { hours: 9, minutes: 0 }
function parseTime(timeStr) {
  const [h, m] = (timeStr || '00:00').split(':').map(Number);
  return { hours: h || 0, minutes: m || 0 };
}

async function updateExpiredBookings() {
  try {
    const now = nowMongolia();
    const snap = await db.collection('bookings')
      .where('status', 'in', ['upcoming', 'active'])
      .get();

    if (snap.empty) return;

    const batch = db.batch();
    let count = 0;

    for (const doc of snap.docs) {
      const data = doc.data();
      const dateKey = data.dateKey; // "2026-03-17"
      const endTime = data.timeSlotEnd; // "10:00"

      if (!dateKey || !endTime) continue;

      const { hours, minutes } = parseTime(endTime);
      const [year, month, day] = dateKey.split('-').map(Number);

      // Захиалгын дуусах цаг (MongoDB UTC+8 дээр)
      const endDateUtc8 = new Date(Date.UTC(year, month - 1, day, hours - 8, minutes));
      // UTC+8 → UTC: hours - 8
      const endDateUtc = new Date(endDateUtc8.getTime());

      const nowUtc = new Date();
      if (nowUtc > endDateUtc) {
        batch.update(doc.ref, { status: 'completed', completedAt: new Date() });
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
      console.log(`[Cron] ${count} захиалга "completed" болголоо`);
    }
  } catch (err) {
    console.error('[Cron] Алдаа:', err.message);
  }
}

function startCron() {
  // Эхлээд нэг удаа ажиллуулна
  updateExpiredBookings();
  // 15 минут тутамд давтана
  const interval = setInterval(updateExpiredBookings, 15 * 60 * 1000);
  console.log('[Cron] Захиалгын статус шинэчлэл эхэллээ (15 мин тутам)');
  return interval;
}

module.exports = { startCron };
