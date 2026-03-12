import Sidebar from "./Sidebar";
import MapView from "./MapView";
import { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "./firebase";

export default function MapPage() {

  const [vehicles, setVehicles] = useState([]);

  useEffect(() => {

    const unsub = onSnapshot(
      collection(db, "trucks"),
      snapshot => {

        const data = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));

        setVehicles(data);
      }
    );

    return unsub;

  }, []);

  return (
    <div style={{ display: "flex", height: "100vh" }}>

      <Sidebar />

      <div style={{ flex: 1 }}>
        <MapView vehicles={vehicles} />
      </div>

    </div>
  );
}