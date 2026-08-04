import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import './App.css'

const API_URL = 'http://localhost:5145/api/stores'
const TENJO_CENTER = [4.8672, -74.1447]

function LocationPicker({ onPick }) {
  useMapEvents({
    click(e) {
      onPick(e.latlng)
    },
  })
  return null
}

function App() {
  const [stores, setStores] = useState([])
  const [pickedLocation, setPickedLocation] = useState(null)
  const [form, setForm] = useState({ name: '', address: '', phone: '', category: '' })
  const [withoutLocation, setWithoutLocation] = useState(false)

  const loadStores = () => {
    fetch(API_URL)
      .then((res) => res.json())
      .then(setStores)
      .catch(() => setStores([]))
  }

  useEffect(() => {
    loadStores()
  }, [])

  const handleSubmit = async (e) => {
    e.preventDefault()
    const body = {
      name: form.name,
      address: form.address,
      phone: form.phone,
      category: form.category,
      latitude: withoutLocation ? null : pickedLocation?.lat,
      longitude: withoutLocation ? null : pickedLocation?.lng,
    }
    await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
    setForm({ name: '', address: '', phone: '', category: '' })
    setPickedLocation(null)
    setWithoutLocation(false)
    loadStores()
  }

  return (
    <div className="container py-4">
      <h1 className="mb-4">TenjoMicilios - Registro de tiendas</h1>

      <div className="row g-4">
        <div className="col-md-7">
          <MapContainer center={TENJO_CENTER} zoom={15} className="map rounded border">
            <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
            <LocationPicker onPick={setPickedLocation} />
            {pickedLocation && <Marker position={pickedLocation} />}
            {stores
              .filter((s) => s.latitude != null && s.longitude != null)
              .map((s) => (
                <Marker key={s.id} position={[s.latitude, s.longitude]} />
              ))}
          </MapContainer>
        </div>

        <div className="col-md-5">
          <form onSubmit={handleSubmit} className="card card-body shadow-sm">
            <div className="form-check mb-3">
              <input
                type="checkbox"
                className="form-check-input"
                id="withoutLocation"
                checked={withoutLocation}
                onChange={(e) => setWithoutLocation(e.target.checked)}
              />
              <label className="form-check-label" htmlFor="withoutLocation">
                Crear sin ubicación en el mapa
              </label>
            </div>

            {!withoutLocation && (
              <p className="text-muted small">
                {pickedLocation
                  ? `Ubicación: ${pickedLocation.lat.toFixed(5)}, ${pickedLocation.lng.toFixed(5)}`
                  : 'Haz clic en el mapa para elegir la ubicación'}
              </p>
            )}

            <div className="mb-2">
              <input
                className="form-control"
                placeholder="Nombre"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                required
              />
            </div>
            <div className="mb-2">
              <input
                className="form-control"
                placeholder="Dirección"
                value={form.address}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
                required
              />
            </div>
            <div className="mb-2">
              <input
                className="form-control"
                placeholder="Teléfono"
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
              />
            </div>
            <div className="mb-3">
              <input
                className="form-control"
                placeholder="Categoría"
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value })}
              />
            </div>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={!withoutLocation && !pickedLocation}
            >
              Guardar tienda
            </button>
          </form>
        </div>
      </div>

      <h2 className="mt-4">Tiendas registradas</h2>
      <ul className="list-group">
        {stores.map((s) => (
          <li key={s.id} className="list-group-item">
            <strong>{s.name}</strong> — {s.address}
            {s.latitude == null && <em className="text-muted"> (sin ubicación en el mapa)</em>}
          </li>
        ))}
      </ul>
    </div>
  )
}

export default App
