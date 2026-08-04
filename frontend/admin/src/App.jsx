import { useState } from 'react'
import StoresScreen from './StoresScreen'
import LiveDrivers from './LiveDrivers'

function App() {
  const [page, setPage] = useState('stores')

  return (
    <div>
      <nav className="navbar navbar-expand navbar-dark bg-dark px-3">
        <span className="navbar-brand">TenjoMicilios Admin</span>
        <div className="navbar-nav">
          <button
            className={`nav-link btn btn-link ${page === 'stores' ? 'text-white fw-bold' : 'text-white-50'}`}
            onClick={() => setPage('stores')}
          >
            Tiendas
          </button>
          <button
            className={`nav-link btn btn-link ${page === 'drivers' ? 'text-white fw-bold' : 'text-white-50'}`}
            onClick={() => setPage('drivers')}
          >
            Conductores en vivo
          </button>
        </div>
      </nav>

      {page === 'stores' ? <StoresScreen /> : <LiveDrivers />}
    </div>
  )
}

export default App
