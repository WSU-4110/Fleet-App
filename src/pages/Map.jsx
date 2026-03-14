import { useEffect, useState } from "react";
import { GoogleMap, useJsApiLoader, Marker, InfoWindow } from "@react-google-maps/api";
import LocationRepository from "../repositories/LocationRepository";

const MAPS_API_KEY = "AIzaSyBpW-EBzPtp8Rpbg5TaUoIcmCj70TVoT_c";

const mapContainerStyle = { width: "100%", height: "100%" };
const defaultCenter = { lat: 37.7749, lng: -122.4194 };

export default function Map() {
  const [employees, setEmployees] = useState([]);
  const [selected, setSelected] = useState(null);
  const [error, setError] = useState("");

  const { isLoaded } = useJsApiLoader({ googleMapsApiKey: MAPS_API_KEY });

  useEffect(() => {
    const fetchLocations = async () => {
      try {
        const data = await LocationRepository.getEmployeeLocations();
        setEmployees(data);
      } catch (err) {
        setError("Failed to load employee locations.");
      }
    };
    fetchLocations();
  }, []);

  const center = employees.length > 0 ? { lat: employees[0].lat, lng: employees[0].lng } : defaultCenter;

  return (
    <div style={styles.wrapper}>
      <div style={styles.header}>
        <h1 style={styles.heading}>Live Map</h1>
        <p style={styles.sub}>{employees.length} employee{employees.length !== 1 ? "s" : ""} tracked</p>
      </div>

      {error && <div style={styles.error}>⚠️ {error}</div>}

      <div style={styles.mapCard}>
        {!isLoaded ? (
          <div style={styles.loading}>Loading map...</div>
        ) : (
          <GoogleMap mapContainerStyle={mapContainerStyle} center={center} zoom={12} options={mapOptions}>
            {employees.map((emp) => (
              <Marker
                key={emp.id}
                position={{ lat: emp.lat, lng: emp.lng }}
                onClick={() => setSelected(emp)}
              />
            ))}
            {selected && (
              <InfoWindow
                position={{ lat: selected.lat, lng: selected.lng }}
                onCloseClick={() => setSelected(null)}
              >
                <div style={styles.infoWindow}>
                  <strong>{selected.name}</strong>
                  {selected.time && <p style={styles.infoTime}>Last seen: {selected.time}</p>}
                  <p style={styles.infoCoords}>{selected.lat.toFixed(5)}, {selected.lng.toFixed(5)}</p>
                </div>
              </InfoWindow>
            )}
          </GoogleMap>
        )}
      </div>
    </div>
  );
}

const mapOptions = {
  zoomControl: true,
  streetViewControl: false,
  mapTypeControl: false,
  fullscreenControl: true,
  styles: [
    { featureType: "poi", elementType: "labels", stylers: [{ visibility: "off" }] },
  ],
};

const styles = {
  wrapper: {
    display: "flex",
    flexDirection: "column",
    height: "100%",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  header: {
    marginBottom: "20px",
  },
  heading: {
    fontSize: "28px",
    fontWeight: "700",
    color: "#111827",
    margin: "0 0 4px 0",
  },
  sub: {
    color: "#6b7280",
    fontSize: "14px",
    margin: 0,
  },
  error: {
    backgroundColor: "#fef2f2",
    border: "1px solid #fca5a5",
    color: "#b91c1c",
    fontSize: "13px",
    padding: "10px 14px",
    borderRadius: "8px",
    marginBottom: "16px",
  },
  mapCard: {
    flex: 1,
    borderRadius: "14px",
    overflow: "hidden",
    boxShadow: "0 4px 20px rgba(0,0,0,0.08)",
    border: "1px solid #e5e7eb",
    minHeight: "500px",
  },
  loading: {
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    height: "500px",
    color: "#6b7280",
    fontSize: "14px",
  },
  infoWindow: {
    fontFamily: "Inter, system-ui, sans-serif",
    fontSize: "13px",
    color: "#111827",
    minWidth: "140px",
  },
  infoTime: {
    margin: "4px 0 0 0",
    color: "#6b7280",
    fontSize: "12px",
  },
  infoCoords: {
    margin: "2px 0 0 0",
    color: "#9ca3af",
    fontSize: "11px",
  },
};
