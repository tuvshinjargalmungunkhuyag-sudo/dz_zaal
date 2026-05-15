const BASE = 'https://13-112-91-27.sslip.io';
const ADMIN_KEY = 'goviyn-sport-admin-2026';

const headers = {
  'Content-Type': 'application/json',
  'X-Admin-Key': ADMIN_KEY,
};

export async function getStats() {
  const res = await fetch(`${BASE}/api/admin/stats`, { headers });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function getBookings(filters = {}) {
  const params = new URLSearchParams();
  if (filters.status)  params.set('status', filters.status);
  if (filters.venueId) params.set('venueId', filters.venueId);
  if (filters.date)    params.set('date', filters.date);
  const res = await fetch(`${BASE}/api/admin/bookings?${params}`, { headers });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function updateBookingStatus(id, status) {
  const res = await fetch(`${BASE}/api/admin/bookings/${id}/status`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({ status }),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function createBooking(data) {
  const res = await fetch(`${BASE}/api/admin/bookings`, {
    method: 'POST',
    headers,
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function getChartData(days = 14) {
  const res = await fetch(`${BASE}/api/admin/chart?days=${days}`, { headers });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function getUsers() {
  const res = await fetch(`${BASE}/api/admin/users`, { headers });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}
