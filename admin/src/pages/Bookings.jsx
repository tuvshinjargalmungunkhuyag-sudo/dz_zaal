import { useEffect, useState, useCallback } from 'react';
import { getBookings, updateBookingStatus } from '../api';

const STATUSES = ['', 'upcoming', 'active', 'completed', 'cancelled'];
const STATUS_LABELS = {
  upcoming:  { label: 'Хүлээгдэж буй', color: '#f59e0b' },
  active:    { label: 'Идэвхтэй',       color: '#10b981' },
  completed: { label: 'Дууссан',         color: '#3b82f6' },
  cancelled: { label: 'Цуцлагдсан',     color: '#ef4444' },
};
const VENUES = [
  { id: '', name: 'Бүх заал' },
  { id: 'goviyn-arena',         name: 'Говийн Арена' },
  { id: 'omnogovi-sport',       name: 'Өмнөговь Спорт' },
  { id: 'goviyn-volleyball',    name: 'Говийн Волейбол' },
  { id: 'stadium-volleyball',   name: 'Стадионы Волейбол' },
  { id: 'central-basketball',   name: 'Цэнтрийн Сагсан' },
];

export default function Bookings() {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState('');
  const [filters, setFilters] = useState({ status: '', venueId: '', date: '' });
  const [updating, setUpdating] = useState(null);

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

  const fmtDate = (iso) => iso ? iso.replace('T', ' ').slice(0, 16) : '—';

  return (
    <div className="page">
      <h1 className="page-title">Захиалгууд</h1>

      <div className="filter-bar">
        <select
          value={filters.status}
          onChange={(e) => setFilters((f) => ({ ...f, status: e.target.value }))}
        >
          <option value="">Бүх статус</option>
          {STATUSES.filter(Boolean).map((s) => (
            <option key={s} value={s}>{STATUS_LABELS[s]?.label ?? s}</option>
          ))}
        </select>

        <select
          value={filters.venueId}
          onChange={(e) => setFilters((f) => ({ ...f, venueId: e.target.value }))}
        >
          {VENUES.map((v) => (
            <option key={v.id} value={v.id}>{v.name}</option>
          ))}
        </select>

        <input
          type="date"
          value={filters.date}
          onChange={(e) => setFilters((f) => ({ ...f, date: e.target.value }))}
        />

        <button className="btn-secondary" onClick={() => setFilters({ status: '', venueId: '', date: '' })}>
          Цэвэрлэх
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
                    <td>{b.timeSlot ?? `${b.startTime}–${b.endTime}`}</td>
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

      {!loading && (
        <div className="table-footer">{bookings.length} захиалга</div>
      )}
    </div>
  );
}
