import { useState } from "react";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = (e) => {
    e.preventDefault();
    console.log("Email:", email);
    console.log("Password:", password);

  };

  return (
  <div style ={styles.container}>
    <div style={styles.card}>
  
  <div style={styles.leftSection}>
    <h1 style={styles.title}>Fleet Tracker</h1>
    <p style={styles.subtitle}>Log in to manage your vehicles</p>
  </div>

  <div style={styles.rightSection}>
    <form onSubmit={handleLogin} style={styles.form}>
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        style={styles.input}
        required
      />

      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        style={styles.input}
        required
      />

      <button type="submit" style={styles.button}>
        Login
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
    backgroundColor: "#f4f6f9",
  },
  card: {
    backgroundColor: "white",
    padding: "50px",
    borderRadius: "12px",
    boxShadow: "0 10px 25px rgba(0,0,0,0.1)",
    width: "1000px",
    height: "350px",                 
    display: "flex",                
    justifyContent: "space-between",
},
  title: {
    marginBottom: "10px",
    fontSize: "50px",
    fontFamily: "Inter, sans-serif",
  },
  subtitle: {
    marginBottom: "20px",
    color: "gray",
  },
leftSection: {
  width: "350px",
  paddingTop: "40px",   
  paddingLeft: "40px",  
},

rightSection: {
  flex: 1,
  display: "flex",
  justifyContent: "center",  
  alignItems: "center",      
},

form: {
  display: "flex",
  flexDirection: "column",
  width: "400px",
},
  input: {
    padding: "12px",
    marginBottom: "15px",
    borderRadius: "6px",
    border: "1px solid #ddd",
  },
  button: {
    padding: "12px",
    borderRadius: "6px",
    border: "none",
    backgroundColor: "#1e3a8a",
    color: "white",
    fontWeight: "bold",
    cursor: "pointer",
  },
};
