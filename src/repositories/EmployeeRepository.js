import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";

const EmployeeRepository = {
  async getAll() {
    const snapshot = await getDocs(collection(db, "users"));
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  },
};

export default EmployeeRepository;
