import { useEffect, useState } from 'react';
import { getBookings } from '../api';

const VENUES = [
  { id: '1', name: 'Говийн Арена'         },
  { id: '2', name: 'Өмнөговь Спорт Заал' },
  { id: '3', name: 'Стадионы Спорт Заал' },
  { id: '4', name: 'Цэнтрийн Спорт Заал' },
];
const TIMES = ['08:00','09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00','19:00'];

const STATUS_COLORS = {
  upcoming:  '#f59e0b',
  active:    '#10b981',
  completed: '#3b82f6',
  cancelled: '#ef4444',
};
const STATUS_LABELS = {
  upcoming:  'Хүлээгдэж буй',
  active:    'Идэвхтэй',
  completed: 'Дууссан',
  cancelled: 'Цуцлагдсан',
};

function todayStr() {
  return new Date().toISOString().slice(0, 10);
}

export default function Schedule() {
  const [date,     setDate]     = useState(todayStr());
  const [bookings, setBookings] = useState([]);
  const [loading,  setLoading]  = useState(false);
  const [tooltip,  setTooltip]  = useState(null); // { booking, x, y }

  useEffect(() => {
    setLoading(true);
    getBookings({ date })
      .then(setBookings)
      .catch(() => setBookings([]))
      .finally(() => setLoading(false));
  }, [date]);

  // Build lookup: venueId + startTime → booking
  const lookup = {};
  bookings.forEach((b) => {
    const key = `${b.venueId}|${b.startTime ?? b.timeSlot?.slice(0, 5)}`;
    lookup[key] = b;
  });

  const bookedCount = bookings.filter((b) => b.status !== 'cancelled').length;
  const totalSlots  = VENUES.length * TIMES.length;

  const shiftDate = (n) => {
    const d = new Date(date);
    d.setDate(d.getDate() + n);
    setDate(d.toISOString().slice(0, 10));
  };

  return (
    <div className="page">
      <h1 className="page-title">Цагийн хуваарь</h1>

      {/* Date nav */}
      <div className="sched-nav">
        <button className="nav-arrow" onClick={() => shiftDate(-1)}>‹</button>
        <input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="sched-date-input" />
        <button className="nav-arrow" onClick={() => shiftDate(1)}>›</button>
        <span className="sched-stat">
          {loading ? 'Уншиж байна...' : `${bookedCount} / ${totalSlots} slot захиалгатай`}
        </span>
      </div>

      {/* Legend */}
      <div className="sched-legend">
        {Object.entries(STATUS_LABELS).map(([k, v]) => (
          <span key={k} className="legend-item">
            <span className="legend-dot" style={{ background: STATUS_COLORS[k] }} />
            {v}
          </span>
        ))}
        <span className="legend-item">
          <span className="legend-dot" style={{ background: '#30363d' }} />
          Чөлөөтэй
        </span>
      </div>

      {/* Grid */}
      <div className="sched-wrap">
        <table className="sched-table">
          <thead>
            <tr>
              <th className="sched-time-col">Цаг</th>
              {VENUES.map((v) => (
                <th key={v.id} className="sched-venue-col">{v.name}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {TIMES.map((time) => (
              <tr key={time}>
                <td className="sched-time-cell">{time}</td>
                {VENUES.map((venue) => {
                  const b = lookup[`${venue.id}|${time}`];
                  const color = b ? STATUS_COLORS[b.status] ?? '#6c63ff' : null;
                  return (
                    <td
                      key={venue.id}
                      className={`sched-slot ${b ? 'booked' : 'free'}`}
                      style={color ? { background: color + '22', borderColor: color + '55' } : {}}
                      onMouseEnter={b ? (e) => {
                        const rect = e.currentTarget.getBoundingClientRect();
                        setTooltip({ booking: b, x: rect.left, y: rect.bottom + 6 });
                      } : undefined}
                      onMouseLeave={() => setTooltip(null)}
                    >
                      {b && (
                        <div className="slot-content" style={{ color }}>
                          <div className="slot-name">{b.userName || b.userEmail?.split('@')[0]}</div>
                          <div className="slot-status">{STATUS_LABELS[b.status]}</div>
                        </div>
                      )}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Tooltip */}
      {tooltip && (
        <div
          className="sched-tooltip"
          style={{ top: tooltip.y, left: Math.min(tooltip.x, window.innerWidth - 230) }}
        >
          <div className="tt-row"><span>Нэр:</span> {tooltip.booking.userName || '—'}</div>
          <div className="tt-row"><span>Имэйл:</span> {tooltip.booking.userEmail}</div>
          <div className="tt-row"><span>Заал:</span> {tooltip.booking.venueName ?? tooltip.booking.venueId}</div>
          <div className="tt-row"><span>Цаг:</span> {tooltip.booking.timeSlot ?? `${tooltip.booking.startTime}–${tooltip.booking.endTime}`}</div>
          <div className="tt-row"><span>Үнэ:</span> {tooltip.booking.price}</div>
          <div className="tt-row">
            <span>Статус:</span>
            <em style={{ color: STATUS_COLORS[tooltip.booking.status] }}>
              {STATUS_LABELS[tooltip.booking.status]}
            </em>
          </div>
        </div>
      )}
    </div>
  );
}
