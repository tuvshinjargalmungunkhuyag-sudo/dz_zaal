const { db } = require('./firebase');

const MONGOLIA_OFFSET_MS = 8 * 60 * 60 * 1000; // UTC+8

// "09:00" → { hours: 9, minutes: 0 }
function parseTime(timeStr) {
  const [h, m] = (timeStr || '00:00').split(':').map(Number);
  return { hours: h || 0, minutes: m || 0 };
}

// dateKey="2026-03-17", endTime="10:00" (Монгол цагаар) → UTC ms
// "00:00" нь дараагийн өдрийн шөнө дунд (24:00) гэж тооцно
function bookingEndUtcMs(dateKey, endTime) {
  const [year, month, day] = dateKey.split('-').map(Number);
  const { hours, minutes } = parseTime(endTime);
  const endHour = (hours === 0 && minutes === 0) ? 24 : hours;
  // Mongolia local → UTC ms (Date.UTC нь өгсөн талбаруудыг UTC гэж тооцох тул
  // Монгол цаг руу хөрвүүлэхийн тулд 8 цаг хасна)
  return Date.UTC(year, month - 1, day, endHour, minutes) - MONGOLIA_OFFSET_MS;
}

async function updateExpiredBookings() {
  try {
    const snap = await db.collection('bookings')
      .where('status', 'in', ['upcoming', 'active'])
      .get();

    if (snap.empty) return;

    const nowMs = Date.now();
    const toComplete = [];

    for (const doc of snap.docs) {
      const data = doc.data();
      const { dateKey, timeSlotEnd, displayTimeSlotEnd } = data;
      if (!dateKey || !timeSlotEnd) continue;

      // Group leader uses displayTimeSlotEnd (overall end) so the booking card
      // stays "upcoming" until the last slot finishes, not just the first slot
      const endUtcMs = bookingEndUtcMs(dateKey, displayTimeSlotEnd || timeSlotEnd);
      if (nowMs > endUtcMs) toComplete.push(doc.ref);
    }

    if (toComplete.length === 0) return;

    // Firestore batch limit: 500 operation тул chunk хэлбэрээр явуулна
    const CHUNK = 499;
    const completedAt = new Date();
    for (let i = 0; i < toComplete.length; i += CHUNK) {
      const batch = db.batch();
      toComplete.slice(i, i + CHUNK).forEach((ref) =>
        batch.update(ref, { status: 'completed', completedAt })
      );
      await batch.commit();
    }
    console.log(`[Cron] ${toComplete.length} захиалга "completed" болголоо`);
  } catch (err) {
    console.error('[Cron] Алдаа:', err.message);
  }
}

function startCron() {
  updateExpiredBookings();
  const interval = setInterval(updateExpiredBookings, 15 * 60 * 1000);
  console.log('[Cron] Захиалгын статус шинэчлэл эхэллээ (15 мин тутам)');
  return interval;
}

module.exports = { startCron };
