import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";

const LocationRepository = {
  async getEmployeeLocations() {
    const snapshot = await getDocs(collection(db, "EmployeeModel"));
    return snapshot.docs
      .map((doc) => {
        const d = doc.data();
        const lat = parseFloat(Array.isArray(d.latitude) ? d.latitude[d.latitude.length - 1] : d.latitude);
        const lng = parseFloat(Array.isArray(d.longitude) ? d.longitude[d.longitude.length - 1] : d.longitude);
        const time = Array.isArray(d.locationTime) ? d.locationTime[d.locationTime.length - 1] : d.locationTime;
        return { id: doc.id, name: d.name, lat, lng, time };
      })
      .filter((e) => !isNaN(e.lat) && !isNaN(e.lng) && e.lat !== 0 && e.lng !== 0);
  },
};

export default LocationRepository;
