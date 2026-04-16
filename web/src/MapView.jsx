import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";

export default function MapView({ vehicles }) {

  return (
    <MapContainer
      center={[42.43, -83.48]}
      zoom={12}
      style={{ height: "100%", width: "100%" }}
    >

      <TileLayer
        attribution='&copy; OpenStreetMap'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />

      {vehicles.map(vehicle => (
        <Marker
          key={vehicle.id}
          position={[vehicle.lat, vehicle.lng]}
        >
          <Popup>
            {vehicle.name}
            <br/>
            Status: {vehicle.status}
          </Popup>
        </Marker>
      ))}

    </MapContainer>
  );
}