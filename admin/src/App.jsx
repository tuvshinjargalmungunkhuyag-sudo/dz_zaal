import { useState } from 'react';
import Dashboard from './pages/Dashboard';
import Bookings  from './pages/Bookings';
import Users     from './pages/Users';
import './App.css';

const NAV = [
  { id: 'dashboard', label: 'Самбар',      icon: '📊' },
  { id: 'bookings',  label: 'Захиалгууд',  icon: '📋' },
  { id: 'users',     label: 'Хэрэглэгчид', icon: '👥' },
];

export default function App() {
  const [page, setPage]       = useState('dashboard');
  const [sideOpen, setSideOpen] = useState(true);

  const Page = page === 'dashboard' ? Dashboard
             : page === 'bookings'  ? Bookings
             : Users;

  return (
    <div className="shell">
      {/* Sidebar */}
      <aside className={`sidebar ${sideOpen ? '' : 'collapsed'}`}>
        <div className="sidebar-brand">
          <span className="brand-icon">🏀</span>
          {sideOpen && <span className="brand-name">Говийн Спорт</span>}
        </div>

        <nav className="sidebar-nav">
          {NAV.map((item) => (
            <button
              key={item.id}
              className={`nav-item ${page === item.id ? 'active' : ''}`}
              onClick={() => setPage(item.id)}
              title={!sideOpen ? item.label : undefined}
            >
              <span className="nav-icon">{item.icon}</span>
              {sideOpen && <span className="nav-label">{item.label}</span>}
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          {sideOpen && <span className="admin-tag">Админ панел</span>}
        </div>
      </aside>

      {/* Main */}
      <div className="main">
        <header className="topbar">
          <button className="toggle-btn" onClick={() => setSideOpen((v) => !v)}>
            {sideOpen ? '◀' : '▶'}
          </button>
          <span className="topbar-title">
            {NAV.find((n) => n.id === page)?.label}
          </span>
          <div className="topbar-right">
            <span className="admin-badge">Админ</span>
          </div>
        </header>

        <main className="content">
          <Page />
        </main>
      </div>
    </div>
  );
}
