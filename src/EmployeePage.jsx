import Sidebar from "./Sidebar";
import { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "./firebase";

export default function EmployeePage() {

  const [employees, setEmployees] = useState([]);

  useEffect(() => {

    const unsub = onSnapshot(
      collection(db, "employees"),
      (snapshot) => {

        const data = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data()
        }));

        setEmployees(data);
      }
    );

    return () => unsub();

  }, []);

  return (
    <div style={styles.layout}>

      <Sidebar />

      <div style={styles.main}>

        <h1 style={styles.title}>Employees</h1>

        <div style={styles.grid}>
          {employees.map((emp) => (
            <div key={emp.id} style={styles.card}>
              <h3>{emp.name}</h3>
              <p>Email: {emp.email}</p>
              <p>Role: {emp.role}</p>
              <p>Phone: {emp.phone}</p>
            </div>
          ))}
        </div>

      </div>

    </div>
  );
}

const styles = {
  layout: {
    display: "flex",
    height: "100vh",
    fontFamily: "Inter, sans-serif"
  },

  main: {
    flex: 1,
    padding: "40px",
    background: "#f4f6fb"
  },

  title: {
    fontSize: "28px",
    fontWeight: "700"
  },

  grid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill,minmax(240px,1fr))",
    gap: "20px",
    marginTop: "20px"
  },

  card: {
    background: "white",
    padding: "20px",
    borderRadius: "12px",
    boxShadow: "0 10px 25px rgba(0,0,0,0.1)"
  }
};