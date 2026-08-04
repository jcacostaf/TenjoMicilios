import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'

const DRIVERS_URL = 'http://localhost:5145/api/drivers'
const TENJO_CENTER = [4.8672, -74.1447]
const POLL_INTERVAL_MS = 5000

function LiveDrivers() {
  const [drivers, setDrivers] = useState([])

  useEffect(() => {
    const loadDrivers = () => {
      fetch(DRIVERS_URL)
        .then((res) => res.json())
        .then(setDrivers)
        .catch(() => setDrivers([]))
    }

    loadDrivers()
    const interval = setInterval(loadDrivers, POLL_INTERVAL_MS)
    return () => clearInterval(interval)
  }, [])

  return (
    <div className="container py-4">
      <h1 className="mb-4">Conductores en vivo</h1>
      <p className="text-muted">La ubicación se actualiza cada 5 segundos.</p>

      <MapContainer center={TENJO_CENTER} zoom={15} className="map rounded border">
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        {drivers.map((d) => (
          <Marker key={d.id} position={[d.latitude, d.longitude]}>
            <Popup>{d.name}</Popup>
          </Marker>
        ))}
      </MapContainer>

      <ul className="list-group mt-3">
        {drivers.map((d) => (
          <li key={d.id} className="list-group-item">
            <strong>{d.name}</strong> — actualizado{' '}
            {new Date(d.updatedAt).toLocaleTimeString()}
          </li>
        ))}
      </ul>
    </div>
  )
}

export default LiveDrivers
