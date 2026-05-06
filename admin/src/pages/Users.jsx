import { useEffect, useState } from 'react';
import { getUsers } from '../api';

export default function Users() {
  const [users, setUsers]     = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState('');
  const [search, setSearch]   = useState('');

  useEffect(() => {
    getUsers()
      .then(setUsers)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const fmtDate = (iso) => iso ? iso.slice(0, 10) : '—';

  const filtered = users.filter((u) => {
    const q = search.toLowerCase();
    return !q ||
      (u.name ?? '').toLowerCase().includes(q) ||
      (u.email ?? '').toLowerCase().includes(q) ||
      (u.phone ?? '').includes(q);
  });

  return (
    <div className="page">
      <h1 className="page-title">Хэрэглэгчид</h1>

      <div className="filter-bar">
        <input
          type="text"
          placeholder="Нэр, имэйл, утасны дугаараар хайх..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ minWidth: 280 }}
        />
        <span className="count-badge">{filtered.length} хэрэглэгч</span>
      </div>

      {error && <div className="center-msg error">Алдаа: {error}</div>}

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Нэр</th>
              <th>Имэйл</th>
              <th>Утас</th>
              <th>Бүртгэгдсэн</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={4} className="cell-center">Уншиж байна...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={4} className="cell-center">Хэрэглэгч олдсонгүй</td></tr>
            ) : (
              filtered.map((u) => (
                <tr key={u.id}>
                  <td>
                    <div className="avatar-row">
                      <div className="avatar">{(u.name ?? u.email ?? '?')[0].toUpperCase()}</div>
                      <span>{u.name ?? '—'}</span>
                    </div>
                  </td>
                  <td>{u.email ?? '—'}</td>
                  <td>{u.phone ?? '—'}</td>
                  <td>{fmtDate(u.createdAt)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
