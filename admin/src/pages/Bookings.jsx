import { useEffect, useState, useCallback } from 'react';
import { getBookings, updateBookingStatus, createBooking } from '../api';

const STATUSES = ['', 'upcoming', 'active', 'completed', 'cancelled'];
const STATUS_LABELS = {
  upcoming:  { label: 'Хүлээгдэж буй', color: '#f59e0b' },
  active:    { label: 'Идэвхтэй',       color: '#10b981' },
  completed: { label: 'Дууссан',         color: '#3b82f6' },
  cancelled: { label: 'Цуцлагдсан',     color: '#ef4444' },
};
const VENUES = [
  { id: '',  name: 'Бүх заал',              price: 0     },
  { id: '1', name: 'Говийн Арена',          price: 15000 },
  { id: '2', name: 'Өмнөговь Спорт Заал',  price: 12000 },
  { id: '3', name: 'Стадионы Спорт Заал',  price: 8000  },
  { id: '4', name: 'Цэнтрийн Спорт Заал',  price: 18000 },
];
const TIMES = ['08:00','09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00','19:00'];

const EMPTY_FORM = { userEmail: '', userName: '', venueId: '', dateKey: '', startTime: '08:00', courtType: '' };

// timeSlot нь зарим захиалгад зөвхөн "09:00" гэж хадгалагдсан тул нэг цаг нэмэн "09:00–10:00" болгоно
function fmtSlot(b) {
  if (b.startTime && b.endTime) return `${b.startTime}–${b.endTime}`;
  const ts = b.timeSlot ?? '';
  if (ts.includes('–') || ts.includes('-')) return ts;
  if (/^\d{2}:\d{2}$/.test(ts)) {
    const end = `${String(parseInt(ts) + 1).padStart(2, '0')}:00`;
    return `${ts}–${end}`;
  }
  return ts || '—';
}

// ── CSV export ────────────────────────────────────────────────────────────────
function exportCSV(bookings) {
  const cols = ['ID','Нэр','Имэйл','Заал','Өдөр','Цаг','Үнэ','Статус','Үүсгэсэн'];
  const rows = bookings.map((b) => [
    b.id,
    b.userName  ?? '',
    b.userEmail ?? '',
    b.venueName ?? b.venueId ?? '',
    b.dateKey   ?? '',
    fmtSlot(b),
    b.price     ?? '',
    STATUS_LABELS[b.status]?.label ?? b.status ?? '',
    b.createdAt ? b.createdAt.slice(0, 16) : '',
  ]);
  const csv = [cols, ...rows]
    .map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(','))
    .join('\n');
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url;
  a.download = `bookings_${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

// ── Create booking modal ──────────────────────────────────────────────────────
function CreateModal({ onClose, onCreated }) {
  const [form,    setForm]    = useState(EMPTY_FORM);
  const [saving,  setSaving]  = useState(false);
  const [err,     setErr]     = useState('');

  const venue    = VENUES.find((v) => v.id === form.venueId);
  const endTime  = form.startTime
    ? `${String(parseInt(form.startTime) + 1).padStart(2, '0')}:00`
    : '';
  const priceStr = venue?.price ? `${venue.price.toLocaleString()}₮` : '';

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  const submit = async (e) => {
    e.preventDefault();
    if (!form.userEmail || !form.venueId || !form.dateKey || !form.startTime) {
      setErr('Бүх шаардлагатай талбарыг бөглөнө үү');
      return;
    }
    setSaving(true);
    setErr('');
    try {
      await createBooking({
        userEmail: form.userEmail,
        userName:  form.userName,
        venueId:   form.venueId,
        venueName: venue?.name ?? form.venueId,
        dateKey:   form.dateKey,
        startTime: form.startTime,
        endTime,
        price:     priceStr,
        courtType: form.courtType,
      });
      onCreated();
      onClose();
    } catch (e) {
      setErr(e.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal">
        <div className="modal-header">
          <span>Захиалга үүсгэх</span>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        <form onSubmit={submit} className="modal-form">
          <label>Имэйл *
            <input type="email" value={form.userEmail} onChange={(e) => set('userEmail', e.target.value)} placeholder="user@example.com" required />
          </label>
          <label>Нэр
            <input type="text" value={form.userName} onChange={(e) => set('userName', e.target.value)} placeholder="Хэрэглэгчийн нэр" />
          </label>
          <label>Заал *
            <select value={form.venueId} onChange={(e) => set('venueId', e.target.value)} required>
              <option value="">-- Заал сонгох --</option>
              {VENUES.filter((v) => v.id).map((v) => (
                <option key={v.id} value={v.id}>{v.name} — {v.price.toLocaleString()}₮</option>
              ))}
            </select>
          </label>
          <label>Өдөр *
            <input type="date" value={form.dateKey} onChange={(e) => set('dateKey', e.target.value)} required />
          </label>
          <label>Эхлэх цаг *
            <select value={form.startTime} onChange={(e) => set('startTime', e.target.value)} required>
              {TIMES.map((t) => <option key={t} value={t}>{t} – {String(parseInt(t)+1).padStart(2,'0')}:00</option>)}
            </select>
          </label>
          <label>Талбайн төрөл
            <input type="text" value={form.courtType} onChange={(e) => set('courtType', e.target.value)} placeholder="half / full / 1 / 2 ..." />
          </label>
          {priceStr && <div className="modal-price">Үнэ: <strong>{priceStr}</strong></div>}
          {err && <div className="modal-err">{err}</div>}
          <div className="modal-actions">
            <button type="button" className="btn-secondary" onClick={onClose}>Болих</button>
            <button type="submit" className="btn-primary" disabled={saving}>
              {saving ? 'Хадгалж байна...' : 'Үүсгэх'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ── Main component ────────────────────────────────────────────────────────────
export default function Bookings() {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading]   = useState(true);
  const [error, setError]       = useState('');
  const [filters, setFilters]   = useState({ status: '', venueId: '', date: '' });
  const [updating, setUpdating] = useState(null);
  const [showCreate, setShowCreate] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    setError('');
    getBookings(filters)
      .then(setBookings)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [filters]);

  useEffect(() => { load(); }, [load]);

  const changeStatus = async (id, status) => {
    setUpdating(id);
    try {
      await updateBookingStatus(id, status);
      await load();
    } catch (e) {
      alert('Алдаа: ' + e.message);
    } finally {
      setUpdating(null);
    }
  };

  return (
    <div className="page">
      <div className="page-header-row">
        <h1 className="page-title">Захиалгууд</h1>
        <button className="btn-primary" onClick={() => setShowCreate(true)}>+ Захиалга үүсгэх</button>
      </div>

      <div className="filter-bar">
        <select value={filters.status} onChange={(e) => setFilters((f) => ({ ...f, status: e.target.value }))}>
          <option value="">Бүх статус</option>
          {STATUSES.filter(Boolean).map((s) => (
            <option key={s} value={s}>{STATUS_LABELS[s]?.label ?? s}</option>
          ))}
        </select>
        <select value={filters.venueId} onChange={(e) => setFilters((f) => ({ ...f, venueId: e.target.value }))}>
          {VENUES.map((v) => <option key={v.id} value={v.id}>{v.name}</option>)}
        </select>
        <input type="date" value={filters.date} onChange={(e) => setFilters((f) => ({ ...f, date: e.target.value }))} />
        <button className="btn-secondary" onClick={() => setFilters({ status: '', venueId: '', date: '' })}>Цэвэрлэх</button>
        <button
          className="btn-export"
          disabled={bookings.length === 0}
          onClick={() => exportCSV(bookings)}
        >
          ⬇ CSV татах
        </button>
      </div>

      {error && <div className="center-msg error">Алдаа: {error}</div>}

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Хэрэглэгч</th>
              <th>Заал</th>
              <th>Өдөр</th>
              <th>Цаг</th>
              <th>Үнэ</th>
              <th>Статус</th>
              <th>Үйлдэл</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} className="cell-center">Уншиж байна...</td></tr>
            ) : bookings.length === 0 ? (
              <tr><td colSpan={7} className="cell-center">Захиалга байхгүй</td></tr>
            ) : (
              bookings.map((b) => {
                const st = STATUS_LABELS[b.status] ?? { label: b.status, color: '#888' };
                return (
                  <tr key={b.id}>
                    <td>
                      <div className="cell-name">{b.userName ?? '—'}</div>
                      <div className="cell-sub">{b.userEmail}</div>
                    </td>
                    <td>{b.venueName ?? b.venueId}</td>
                    <td>{b.dateKey}</td>
                    <td>{fmtSlot(b)}</td>
                    <td>{b.price}</td>
                    <td>
                      <span className="badge" style={{ background: st.color + '22', color: st.color }}>
                        {st.label}
                      </span>
                    </td>
                    <td>
                      <select
                        className="status-select"
                        value={b.status}
                        disabled={updating === b.id}
                        onChange={(e) => changeStatus(b.id, e.target.value)}
                      >
                        {STATUSES.filter(Boolean).map((s) => (
                          <option key={s} value={s}>{STATUS_LABELS[s]?.label ?? s}</option>
                        ))}
                      </select>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {!loading && <div className="table-footer">{bookings.length} захиалга</div>}

      {showCreate && (
        <CreateModal onClose={() => setShowCreate(false)} onCreated={load} />
      )}
    </div>
  );
}
