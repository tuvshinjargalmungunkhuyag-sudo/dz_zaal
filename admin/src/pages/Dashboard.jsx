import { useEffect, useState } from 'react';
import {
  BarChart, Bar, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';
import { getStats, getChartData } from '../api';

const STAT_CARDS = [
  { key: 'total',     label: 'Нийт захиалга',   icon: '📋', color: '#6c63ff' },
  { key: 'upcoming',  label: 'Хүлээгдэж буй',   icon: '⏳', color: '#f59e0b' },
  { key: 'active',    label: 'Идэвхтэй',         icon: '🟢', color: '#10b981' },
  { key: 'completed', label: 'Дууссан',           icon: '✅', color: '#3b82f6' },
  { key: 'cancelled', label: 'Цуцлагдсан',       icon: '❌', color: '#ef4444' },
  { key: 'today',     label: 'Өнөөдөр',          icon: '📅', color: '#8b5cf6' },
];

const RANGE_OPTIONS = [
  { label: '7 хоног',  days: 7  },
  { label: '14 хоног', days: 14 },
  { label: '30 хоног', days: 30 },
];

const tickFormatter = (val) => val.slice(5); // "2026-05-06" → "05-06"
const fmtRevenue = (val) => `₮${(val / 1000).toFixed(0)}к`;

export default function Dashboard() {
  const [stats,     setStats]     = useState(null);
  const [chartData, setChartData] = useState([]);
  const [days,      setDays]      = useState(14);
  const [loading,   setLoading]   = useState(true);
  const [error,     setError]     = useState('');

  useEffect(() => {
    Promise.all([getStats(), getChartData(days)])
      .then(([s, c]) => { setStats(s); setChartData(c); })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [days]);

  if (loading) return <div className="center-msg">Уншиж байна...</div>;
  if (error)   return <div className="center-msg error">Алдаа: {error}</div>;

  const fmt = (n) => n?.toLocaleString('mn-MN') ?? '—';

  return (
    <div className="page">
      <h1 className="page-title">Хяналтын самбар</h1>

      {/* Stat cards */}
      <div className="stat-grid">
        {STAT_CARDS.map(({ key, label, icon, color }) => (
          <div className="stat-card" key={key} style={{ borderTop: `3px solid ${color}` }}>
            <span className="stat-icon">{icon}</span>
            <div className="stat-value" style={{ color }}>{fmt(stats[key])}</div>
            <div className="stat-label">{label}</div>
          </div>
        ))}
      </div>

      {/* Revenue summary */}
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

      {/* Chart range selector */}
      <div className="chart-header">
        <span className="chart-title">Захиалгын статистик</span>
        <div className="range-tabs">
          {RANGE_OPTIONS.map((o) => (
            <button
              key={o.days}
              className={`range-tab ${days === o.days ? 'active' : ''}`}
              onClick={() => setDays(o.days)}
            >
              {o.label}
            </button>
          ))}
        </div>
      </div>

      {/* Booking count bar chart */}
      <div className="chart-card">
        <div className="chart-subtitle">Өдөр тутмын захиалга</div>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={chartData} margin={{ top: 8, right: 8, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#30363d" vertical={false} />
            <XAxis dataKey="date" tickFormatter={tickFormatter} tick={{ fill: '#8b949e', fontSize: 11 }} axisLine={false} tickLine={false} />
            <YAxis allowDecimals={false} tick={{ fill: '#8b949e', fontSize: 11 }} axisLine={false} tickLine={false} />
            <Tooltip
              contentStyle={{ background: '#1f2937', border: '1px solid #30363d', borderRadius: 8, fontSize: 12 }}
              labelStyle={{ color: '#e6edf3' }}
              itemStyle={{ color: '#a78bfa' }}
              formatter={(v) => [v, 'Захиалга']}
            />
            <Bar dataKey="count" fill="#6c63ff" radius={[4, 4, 0, 0]} maxBarSize={32} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Revenue area chart */}
      <div className="chart-card">
        <div className="chart-subtitle">Өдөр тутмын орлого</div>
        <ResponsiveContainer width="100%" height={200}>
          <AreaChart data={chartData} margin={{ top: 8, right: 8, left: -10, bottom: 0 }}>
            <defs>
              <linearGradient id="rev-grad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%"  stopColor="#10b981" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#10b981" stopOpacity={0}   />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#30363d" vertical={false} />
            <XAxis dataKey="date" tickFormatter={tickFormatter} tick={{ fill: '#8b949e', fontSize: 11 }} axisLine={false} tickLine={false} />
            <YAxis tickFormatter={fmtRevenue} tick={{ fill: '#8b949e', fontSize: 11 }} axisLine={false} tickLine={false} />
            <Tooltip
              contentStyle={{ background: '#1f2937', border: '1px solid #30363d', borderRadius: 8, fontSize: 12 }}
              labelStyle={{ color: '#e6edf3' }}
              itemStyle={{ color: '#10b981' }}
              formatter={(v) => [`₮${v.toLocaleString()}`, 'Орлого']}
            />
            <Area type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={2} fill="url(#rev-grad)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
