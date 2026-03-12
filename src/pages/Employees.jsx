import { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";

export default function Employees() {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const fetchEmployees = async () => {
      try {
        const snapshot = await getDocs(collection(db, "users"));
        const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        setEmployees(data);
      } catch (err) {
        setError("Failed to load employees.");
      } finally {
        setLoading(false);
      }
    };
    fetchEmployees();
  }, []);

  return (
    <div>
      <div style={styles.header}>
        <div>
          <h1 style={styles.heading}>Employees</h1>
          <p style={styles.sub}>{loading ? "Loading..." : `${employees.length} team members`}</p>
        </div>
      </div>

      {error && <div style={styles.error}>⚠️ {error}</div>}

      <div style={styles.tableWrapper}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Username</th>
              <th style={styles.th}>Name</th>
              <th style={styles.th}>Email</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={3} style={styles.loadingCell}>Loading employees...</td>
              </tr>
            ) : employees.length === 0 ? (
              <tr>
                <td colSpan={3} style={styles.loadingCell}>No employees found.</td>
              </tr>
            ) : (
              employees.map((emp, i) => (
                <tr key={emp.id} style={{ backgroundColor: i % 2 === 0 ? "white" : "#f8faff" }}>
                  <td style={styles.td}>
                    <div style={styles.usernameCell}>
                      <div style={styles.avatar}>
                        {(emp.name || emp.username || "?").charAt(0).toUpperCase()}
                      </div>
                      <span style={styles.username}>@{emp.username}</span>
                    </div>
                  </td>
                  <td style={styles.td}>
                    <span style={styles.name}>{emp.name}</span>
                  </td>
                  <td style={styles.td}>
                    <span style={styles.email}>{emp.email}</span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

const styles = {
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: "28px",
  },
  heading: {
    fontSize: "28px",
    fontWeight: "700",
    color: "#111827",
    margin: "0 0 4px 0",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  sub: {
    color: "#6b7280",
    fontSize: "14px",
    margin: 0,
    fontFamily: "Inter, system-ui, sans-serif",
  },
  error: {
    backgroundColor: "#fef2f2",
    border: "1px solid #fca5a5",
    color: "#b91c1c",
    fontSize: "13px",
    padding: "10px 14px",
    borderRadius: "8px",
    marginBottom: "20px",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  tableWrapper: {
    backgroundColor: "white",
    borderRadius: "14px",
    boxShadow: "0 4px 20px rgba(0,0,0,0.06)",
    overflow: "hidden",
    border: "1px solid #e5e7eb",
  },
  table: {
    width: "100%",
    borderCollapse: "collapse",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  th: {
    padding: "14px 20px",
    textAlign: "left",
    fontSize: "11px",
    fontWeight: "700",
    color: "#6b7280",
    textTransform: "uppercase",
    letterSpacing: "0.6px",
    backgroundColor: "#f9fafb",
    borderBottom: "1px solid #e5e7eb",
  },
  td: {
    padding: "14px 20px",
    borderBottom: "1px solid #f3f4f6",
    verticalAlign: "middle",
  },
  loadingCell: {
    padding: "32px 20px",
    textAlign: "center",
    color: "#9ca3af",
    fontSize: "14px",
  },
  usernameCell: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
  },
  avatar: {
    width: "34px",
    height: "34px",
    borderRadius: "50%",
    background: "linear-gradient(135deg, #1e3a8a, #2563eb)",
    color: "white",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontWeight: "700",
    fontSize: "14px",
    flexShrink: 0,
  },
  username: {
    fontSize: "14px",
    fontWeight: "600",
    color: "#1e3a8a",
  },
  name: {
    fontSize: "14px",
    fontWeight: "500",
    color: "#111827",
  },
  email: {
    fontSize: "14px",
    color: "#6b7280",
  },
};
