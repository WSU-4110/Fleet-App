export default function Map() {
  return (
    <div>
      <h1 style={styles.heading}>Map</h1>
      <p style={styles.sub}>Live vehicle tracking and routes.</p>
    </div>
  );
}

const styles = {
  heading: { fontSize: "28px", fontWeight: "700", color: "#111827", margin: "0 0 8px 0" },
  sub: { color: "#6b7280", fontSize: "15px" },
};
