import { useState } from "react";
import { sendPasswordResetEmail } from "firebase/auth";
import { auth } from "./firebase";
import { useNavigate } from "react-router-dom";
import { authStyles as styles } from "./styles";

export default function ForgotPassword(){

  const [email,setEmail] = useState("");
  const [message,setMessage] = useState("");
  const navigate = useNavigate();

  const handleReset = async(e)=>{
    e.preventDefault();

    try{
      await sendPasswordResetEmail(auth,email);
      setMessage("Password reset email sent.");
    }
    catch{
      setMessage("Could not send reset email.");
    }
  };

  return(
    <div style={styles.container}>
      <div style={styles.card}>

        <div style={styles.leftSection}>
          <div style={styles.logoMark}>🚛</div>
          <h1 style={styles.title}>Fleet Tracker</h1>
          <p style={styles.subtitle}>
            Reset your account password.
          </p>
        </div>

        <div style={styles.rightSection}>
          <h2 style={styles.formTitle}>Forgot Password</h2>

          <form onSubmit={handleReset} style={styles.form}>

            <label style={styles.label}>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e)=>setEmail(e.target.value)}
              style={styles.input}
              required
            />

            {message && <div style={styles.success}>{message}</div>}

            <button style={styles.button}>
              Send Reset Email
            </button>

          </form>

          <p style={styles.linkRow}>
            Back to{" "}
            <span style={styles.link} onClick={()=>navigate("/login")}>
              Login
            </span>
          </p>

        </div>

      </div>
    </div>
  );
}