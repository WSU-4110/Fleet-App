import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "./firebase";
import { useNavigate } from "react-router-dom";
import { authStyles as styles } from "./styles";

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

      setTimeout(() => {
        navigate("/");
      }, 800);

    } catch (err) {
      setError("Invalid email or password.");
    }

    setLoading(false);
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>

        {/* LEFT SIDE */}
        <div style={styles.leftSection}>
          <div style={styles.logoMark}>🚛</div>
          <h1 style={styles.title}>Fleet Tracker</h1>
          <p style={styles.subtitle}>
            Manage your vehicles, routes, and drivers — all in one place.
          </p>
        </div>


        {/* RIGHT SIDE */}
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
                ✅ Login successful
              </div>
            )}

            {error && (
              <div style={styles.error}>
                ⚠️ {error}
              </div>
            )}

            <button type="submit" style={styles.button} disabled={loading}>
              {loading ? "Signing in..." : "Sign in"}
            </button>

          </form>


          {/* FORGOT PASSWORD LINK */}
          <p style={styles.linkRow}>
            <span
              style={styles.link}
              onClick={() => navigate("/forgot-password")}
            >
              Forgot password?
            </span>
          </p>


          {/* SIGNUP LINK */}
          <p style={styles.linkRow}>
            Don't have an account?{" "}
            <span
              style={styles.link}
              onClick={() => navigate("/signup")}
            >
              Sign up
            </span>
          </p>

        </div>
      </div>
    </div>
  );
}

