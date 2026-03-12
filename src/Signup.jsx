import { useState } from "react";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth } from "./firebase";
import { useNavigate } from "react-router-dom";
import { authStyles as styles } from "./styles";

export default function Signup() {

  const [email,setEmail] = useState("");
  const [password,setPassword] = useState("");
  const [error,setError] = useState("");
  const navigate = useNavigate();

  const handleSignup = async(e) => {
    e.preventDefault();
    setError("");

    try{
      await createUserWithEmailAndPassword(auth,email,password);
      navigate("/dashboard");
    }
    catch(err){
      setError("Could not create account.");
    }
  };

  return(
    <div style={styles.container}>
      <div style={styles.card}>

        <div style={styles.leftSection}>
          <div style={styles.logoMark}>🚛</div>
          <h1 style={styles.title}>Fleet Tracker</h1>
          <p style={styles.subtitle}>
            Create your fleet management account.
          </p>
        </div>

        <div style={styles.rightSection}>
          <h2 style={styles.formTitle}>Create account</h2>

          <form onSubmit={handleSignup} style={styles.form}>

            <label style={styles.label}>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e)=>setEmail(e.target.value)}
              style={styles.input}
              required
            />

            <label style={styles.label}>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e)=>setPassword(e.target.value)}
              style={styles.input}
              required
            />

            {error && <div style={styles.error}>{error}</div>}

            <button style={styles.button}>Create Account</button>

          </form>

          <p style={styles.linkRow}>
            Already have an account?{" "}
            <span style={styles.link} onClick={()=>navigate("/login")}>
              Login
            </span>
          </p>

        </div>
      </div>
    </div>
  );
}