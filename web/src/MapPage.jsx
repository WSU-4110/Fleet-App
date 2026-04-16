import { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "./firebase";
import { useAuth } from "./AuthContext";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

export default function MapPage() {
  const { businessId } = useAuth();
  const [employees, setEmployees] = useState([]);

  useEffect(() => {
    if (!businessId) return;

    const unsub = onSnapshot(
      collection(db, "businesses", businessId, "employees"),
      (snapshot) => {
        const data = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setEmployees(data);
      }
    );

    return unsub;
  }, [businessId]);

  // 🔥 Custom marker
  const createEmployeeIcon = (emp) => {
    const initial = (emp.name || emp.username || "?")
      .charAt(0)
      .toUpperCase();

    const isActive = emp.isClockedIn;

    const bg = isActive
      ? "linear-gradient(135deg, #16a34a, #22c55e)" // green
      : "linear-gradient(135deg, #9ca3af, #6b7280)"; // gray

    return L.divIcon({
      className: "",
      html: `
        <div style="
          position: relative;
          width: 38px;
          height: 38px;
        ">
          ${
            isActive
              ? `<span style="
                  position:absolute;
                  width:100%;
                  height:100%;
                  border-radius:50%;
                  background:#22c55e;
                  opacity:0.5;
                  animation:pulse 1.5s infinite;
                "></span>`
              : ""
          }

          <div style="
            width: 38px;
            height: 38px;
            border-radius: 50%;
            background: ${bg};
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 15px;
            border: 2px solid white;
            box-shadow: 0 3px 10px rgba(0,0,0,0.3);
          ">
            ${emp.pinEmoji || initial}
          </div>
        </div>

        <style>
          @keyframes pulse {
            0% { transform: scale(1); opacity: 0.6; }
            70% { transform: scale(1.8); opacity: 0; }
            100% { transform: scale(1); opacity: 0; }
          }
        </style>
      `,
      iconSize: [38, 38],
      iconAnchor: [19, 19],
    });
  };

  return (
    <div style={{ height: "100%", width: "100%" }}>
      <MapContainer
        center={[42.36, -83.07]}
        zoom={13}
        style={{ height: "100%", width: "100%" }}
      >
        <TileLayer
          attribution="&copy; OpenStreetMap"
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {employees.map((emp) => {
          if (!emp.latitude || !emp.longitude) return null;

          return (
            <Marker
              key={emp.id}
              position={[emp.latitude, emp.longitude]}
              icon={createEmployeeIcon(emp)}
            >
              <Popup>
                <b>{emp.name || emp.username}</b>
                <br />
                Status: {emp.isClockedIn ? "🟢 Clocked In" : "⚪ Clocked Out"}
                <br />
                Speed: {Math.round(emp.speedMPH || 0)} mph
                <br />
                Last seen: {emp.lastSeenTimeReadable || "N/A"}
              </Popup>
            </Marker>
          );
        })}
      </MapContainer>
    </div>
  );
}