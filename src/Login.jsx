import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "./firebase";
import { useNavigate } from "react-router-dom";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
      setSuccess(true);
      setTimeout(() => navigate("/"), 800);
    } catch (err) {
      setError("Invalid email or password.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>

        {/* Left panel */}
        <div style={styles.leftSection}>
          <div style={styles.logoMark}>🚛</div>
          <h1 style={styles.title}>Fleet Tracker</h1>
          <p style={styles.subtitle}>Manage your vehicles, routes, and drivers — all in one place.</p>
          <div style={styles.dots}>
            <span style={styles.dot} />
            <span style={{ ...styles.dot, opacity: 0.5 }} />
            <span style={{ ...styles.dot, opacity: 0.3 }} />
          </div>
        </div>

        {/* Right panel */}
        <div style={styles.rightSection}>
          <h2 style={styles.formTitle}>Welcome back</h2>
          <p style={styles.formSubtitle}>Sign in to your account</p>

          <form onSubmit={handleLogin} style={styles.form}>
            <label style={styles.label}>Email</label>
            <input
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={styles.input}
              required
            />

            <label style={styles.label}>Password</label>
            <input
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={styles.input}
              required
            />

            {success && (
              <div style={styles.success}>
                ✅ Authenticated successfully!
              </div>
            )}
            {error && (
              <div style={styles.error}>
                ⚠️ {error}
              </div>
            )}

            <button type="submit" style={styles.button} disabled={loading}>
              {loading ? "Signing in..." : "Sign in →"}
            </button>
          </form>
        </div>

      </div>
    </div>
  );
}

const styles = {
  container: {
    height: "100vh",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    background: "linear-gradient(135deg, #e8edf7 0%, #f4f6fb 100%)",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  card: {
    display: "flex",
    width: "900px",
    minHeight: "500px",
    borderRadius: "20px",
    overflow: "hidden",
    boxShadow: "0 25px 60px rgba(0,0,0,0.12)",
  },
  leftSection: {
    width: "380px",
    background: "linear-gradient(160deg, #1e3a8a 0%, #1e40af 60%, #2563eb 100%)",
    padding: "60px 48px",
    display: "flex",
    flexDirection: "column",
    justifyContent: "center",
    color: "white",
  },
  logoMark: {
    fontSize: "40px",
    marginBottom: "24px",
  },
  title: {
    fontSize: "36px",
    fontWeight: "800",
    margin: "0 0 16px 0",
    lineHeight: 1.2,
    letterSpacing: "-0.5px",
  },
  subtitle: {
    fontSize: "15px",
    color: "rgba(255,255,255,0.75)",
    lineHeight: 1.7,
    margin: "0 0 40px 0",
  },
  dots: {
    display: "flex",
    gap: "8px",
  },
  dot: {
    width: "8px",
    height: "8px",
    borderRadius: "50%",
    backgroundColor: "white",
  },
  rightSection: {
    flex: 1,
    backgroundColor: "white",
    padding: "60px 48px",
    display: "flex",
    flexDirection: "column",
    justifyContent: "center",
  },
  formTitle: {
    fontSize: "26px",
    fontWeight: "700",
    color: "#111827",
    margin: "0 0 6px 0",
  },
  formSubtitle: {
    fontSize: "14px",
    color: "#6b7280",
    margin: "0 0 36px 0",
  },
  form: {
    display: "flex",
    flexDirection: "column",
  },
  label: {
    fontSize: "13px",
    fontWeight: "600",
    color: "#374151",
    marginBottom: "6px",
    letterSpacing: "0.3px",
  },
  input: {
    padding: "12px 16px",
    marginBottom: "20px",
    borderRadius: "10px",
    border: "1.5px solid #e5e7eb",
    fontSize: "15px",
    color: "#111827",
    outline: "none",
    backgroundColor: "#f9fafb",
  },
  success: {
    backgroundColor: "#f0fdf4",
    border: "1px solid #86efac",
    color: "#15803d",
    fontSize: "13px",
    padding: "10px 14px",
    borderRadius: "8px",
    marginBottom: "16px",
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
  button: {
    padding: "13px",
    borderRadius: "10px",
    border: "none",
    background: "linear-gradient(135deg, #1e3a8a, #2563eb)",
    color: "white",
    fontWeight: "700",
    fontSize: "15px",
    cursor: "pointer",
    letterSpacing: "0.3px",
    marginTop: "4px",
    boxShadow: "0 4px 14px rgba(37,99,235,0.4)",
  },
};
