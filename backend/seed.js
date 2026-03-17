require('dotenv').config();
const { db } = require('./firebase');

const fixedBookings = [
  {
    venueId: '1',
    organizationName: 'Аймгийн Засаг Дарга',
    weekDays: [1, 3], // Даваа, Лхагва
    startHour: 9,
    endHour: 11,
  },
  {
    venueId: '1',
    organizationName: 'Аймгийн Засаг Дарга',
    weekDays: [5], // Баасан
    startHour: 10,
    endHour: 12,
  },
  {
    venueId: '3',
    organizationName: 'ӨМААГ',
    weekDays: [2, 4], // Мягмар, Пүрэв
    startHour: 14,
    endHour: 16,
  },
  {
    venueId: '5',
    organizationName: 'Даланзадгад хотын ИТХ',
    weekDays: [1, 2, 3, 4, 5], // Ажлын өдрүүд
    startHour: 8,
    endHour: 10,
  },
];

async function seed() {
  console.log('Seed эхэлж байна...');

  // Хуучин өгөгдлийг устгах
  const existing = await db.collection('fixed_bookings').get();
  const deleteOps = existing.docs.map((d) => d.ref.delete());
  await Promise.all(deleteOps);
  console.log(`${existing.size} хуучин бичлэг устгагдлаа`);

  // Шинэ өгөгдөл оруулах
  for (const item of fixedBookings) {
    await db.collection('fixed_bookings').add({
      ...item,
      createdAt: new Date(),
    });
    console.log(`✓ ${item.organizationName} — заал ${item.venueId}`);
  }

  console.log('\nSeed амжилттай дууслаа!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed алдаа:', err.message);
  process.exit(1);
});
