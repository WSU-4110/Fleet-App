import { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../AuthContext";

export default function Home() {
  const { user, businessId } = useAuth();

  const [employees, setEmployees] = useState([]);
  const [ownerName, setOwnerName] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      if (!businessId) return;

      try {
        // Employees
        const empSnap = await getDocs(
          collection(db, "businesses", businessId, "employees")
        );

        const empData = empSnap.docs.map((d) => ({
          id: d.id,
          ...d.data(),
        }));

        setEmployees(empData);

        // Business owner
        const businessSnap = await getDocs(collection(db, "businesses"));
        const business = businessSnap.docs.find(
          (doc) => doc.id === businessId
        );

        if (business) {
          setOwnerName(business.data().ownerName || "Owner");
        }

      } catch (err) {
        console.log(err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [businessId]);

  if (loading) {
    return <div style={{ padding: "30px" }}>Loading dashboard...</div>;
  }

  return (
    <div>
      {/* HEADER */}
      <div style={styles.header}>
        <h1 style={styles.heading}>
          Welcome back, {ownerName} 👋
        </h1>
        <p style={styles.sub}>
          Here’s what your team is doing right now
        </p>
      </div>

      {/* STATS */}
      <div style={styles.statsRow}>
        <div style={styles.statCard}>
          <h3 style={styles.statNumber}>{employees.length}</h3>
          <p style={styles.statLabel}>Total Employees</p>
        </div>

        <div style={styles.statCard}>
          <h3 style={styles.statNumber}>
            {employees.filter(e => e.isClockedIn).length}
          </h3>
          <p style={styles.statLabel}>Clocked In</p>
        </div>

        <div style={styles.statCard}>
          <h3 style={styles.statNumber}>
            {employees.filter(e => !e.isClockedIn).length}
          </h3>
          <p style={styles.statLabel}>Clocked Out</p>
        </div>
      </div>

      {/* TABLE */}
      <div style={styles.tableWrapper}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Employee</th>
              <th style={styles.th}>Status</th>
            </tr>
          </thead>

          <tbody>
            {employees.length === 0 ? (
              <tr>
                <td colSpan="2" style={styles.loadingCell}>
                  No employees found.
                </td>
              </tr>
            ) : (
              employees.map((emp, i) => (
                <tr
                  key={emp.id}
                  style={{
                    backgroundColor:
                      i % 2 === 0 ? "white" : "#f8faff",
                  }}
                >
                  <td style={styles.td}>
                    <div style={styles.userRow}>
                      <div style={styles.avatar}>
                        {(emp.name || emp.username || "?")
                          .charAt(0)
                          .toUpperCase()}
                      </div>
                      <div>
                        <div style={styles.name}>{emp.name}</div>
                        <div style={styles.username}>
                          @{emp.username}
                        </div>
                      </div>
                    </div>
                  </td>

                  <td style={styles.td}>
                    <span
                      style={{
                        ...styles.statusBadge,
                        backgroundColor: emp.isClockedIn
                          ? "#dcfce7"
                          : "#fee2e2",
                        color: emp.isClockedIn
                          ? "#166534"
                          : "#991b1b",
                      }}
                    >
                      {emp.isClockedIn ? "Clocked In" : "Clocked Out"}
                    </span>
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

/* ================= STYLES ================= */

const styles = {
  header: {
    marginBottom: "28px",
  },
  heading: {
    fontSize: "28px",
    fontWeight: "700",
    color: "#111827",
    marginBottom: "4px",
  },
  sub: {
    color: "#6b7280",
    fontSize: "14px",
  },

  statsRow: {
    display: "flex",
    gap: "16px",
    marginBottom: "24px",
  },
  statCard: {
    flex: 1,
    background: "white",
    padding: "20px",
    borderRadius: "12px",
    boxShadow: "0 4px 20px rgba(0,0,0,0.05)",
  },
  statNumber: {
    fontSize: "22px",
    fontWeight: "700",
  },
  statLabel: {
    fontSize: "13px",
    color: "#6b7280",
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
  },
  th: {
    padding: "14px 20px",
    textAlign: "left",
    fontSize: "11px",
    fontWeight: "700",
    color: "#6b7280",
    textTransform: "uppercase",
    backgroundColor: "#f9fafb",
  },
  td: {
    padding: "14px 20px",
  },
  loadingCell: {
    padding: "30px",
    textAlign: "center",
    color: "#9ca3af",
  },

  userRow: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
  },
  avatar: {
    width: "36px",
    height: "36px",
    borderRadius: "50%",
    background: "linear-gradient(135deg, #1e3a8a, #2563eb)",
    color: "white",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontWeight: "700",
  },
  name: {
    fontWeight: "600",
    color: "#111827",
  },
  username: {
    fontSize: "12px",
    color: "#6b7280",
  },

  statusBadge: {
    padding: "6px 10px",
    borderRadius: "999px",
    fontSize: "12px",
    fontWeight: "600",
  },
};