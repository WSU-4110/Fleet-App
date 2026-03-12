export default function Employees() {
  return (
    <div>
      <h1 style={styles.heading}>Employees</h1>
      <p style={styles.sub}>View and manage your team.</p>
    </div>
  );
}

const styles = {
  heading: { fontSize: "28px", fontWeight: "700", color: "#111827", margin: "0 0 8px 0" },
  sub: { color: "#6b7280", fontSize: "15px" },
};
