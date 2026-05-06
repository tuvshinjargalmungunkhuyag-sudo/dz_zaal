import { useEffect, useState } from 'react';
import { getStats } from '../api';

const STAT_CARDS = [
  { key: 'total',     label: 'Нийт захиалга',   icon: '📋', color: '#6c63ff' },
  { key: 'upcoming',  label: 'Хүлээгдэж буй',   icon: '⏳', color: '#f59e0b' },
  { key: 'active',    label: 'Идэвхтэй',         icon: '🟢', color: '#10b981' },
  { key: 'completed', label: 'Дууссан',           icon: '✅', color: '#3b82f6' },
  { key: 'cancelled', label: 'Цуцлагдсан',       icon: '❌', color: '#ef4444' },
  { key: 'today',     label: 'Өнөөдөр',          icon: '📅', color: '#8b5cf6' },
];

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    getStats()
      .then(setStats)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="center-msg">Уншиж байна...</div>;
  if (error)   return <div className="center-msg error">Алдаа: {error}</div>;

  const fmt = (n) => n?.toLocaleString('mn-MN') ?? '—';

  return (
    <div className="page">
      <h1 className="page-title">Хяналтын самбар</h1>

      <div className="stat-grid">
        {STAT_CARDS.map(({ key, label, icon, color }) => (
          <div className="stat-card" key={key} style={{ borderTop: `3px solid ${color}` }}>
            <span className="stat-icon">{icon}</span>
            <div className="stat-value" style={{ color }}>{fmt(stats[key])}</div>
            <div className="stat-label">{label}</div>
          </div>
        ))}
      </div>

      <div className="revenue-section">
        <div className="revenue-card">
          <div className="revenue-label">Өнөөдрийн орлого</div>
          <div className="revenue-value">₮{fmt(stats.todayRevenue)}</div>
        </div>
        <div className="revenue-card">
          <div className="revenue-label">Нийт орлого</div>
          <div className="revenue-value highlight">₮{fmt(stats.totalRevenue)}</div>
        </div>
      </div>
    </div>
  );
}
