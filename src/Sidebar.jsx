import { NavLink, useNavigate } from "react-router-dom";
import { signOut } from "firebase/auth";
import { auth } from "./firebase";
import { Home, CreditCard, Users, Map, LogOut, Truck, Clock } from "lucide-react";

const navItems = [
  { label: "Home", path: "/", icon: Home },
  { label: "Expenses", path: "/expenses", icon: CreditCard },
  { label: "Employees", path: "/employees", icon: Users },
  { label: "Shifts", path: "/shifts", icon: Clock },
  { label: "Map", path: "/map", icon: Map },
];

export default function Sidebar() {
  const navigate = useNavigate();

  const handleLogout = async () => {
    await signOut(auth);
    navigate("/login");
  };

  return (
    <div style={styles.sidebar}>
      {/* Logo */}
      <div style={styles.logoWrapper}>
        <div style={styles.logoIconBox}>
          <Truck size={22} color="white" />
        </div>
        <span style={styles.logoText}>Fleet Tracker</span>
      </div>

      <div style={styles.divider} />

      {/* Nav */}
      <nav style={styles.nav}>
        {navItems.map(({ label, path, icon: Icon }) => (
          <NavLink
            key={path}
            to={path}
            end={path === "/"}
            style={({ isActive }) =>
              isActive ? { ...styles.navItem, ...styles.navItemActive } : styles.navItem
            }
          >
            {({ isActive }) => (
              <>
                <div style={isActive ? styles.iconBoxActive : styles.iconBox}>
                  <Icon size={17} color={isActive ? "#1e3a8a" : "rgba(255,255,255,0.7)"} />
                </div>
                <span style={isActive ? styles.navLabelActive : styles.navLabel}>{label}</span>
                {isActive && <div style={styles.activePill} />}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      <div style={styles.spacer} />

      {/* Logout */}
      <div style={styles.divider} />
      <button onClick={handleLogout} style={styles.logoutBtn}>
        <div style={styles.logoutIconBox}>
          <LogOut size={17} color="white" />
        </div>
        <span style={styles.logoutLabel}>Logout</span>
      </button>
    </div>
  );
}

const styles = {
  sidebar: {
    width: "250px",
    height: "100vh",
    background: "linear-gradient(160deg, #1e3a8a 0%, #1e40af 60%, #2563eb 100%)",
    display: "flex",
    flexDirection: "column",
    padding: "24px 14px",
    boxSizing: "border-box",
    flexShrink: 0,
    fontFamily: "Inter, system-ui, sans-serif",
  },
  logoWrapper: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    padding: "4px 8px 20px 8px",
  },
  logoIconBox: {
    width: "38px",
    height: "38px",
    borderRadius: "10px",
    backgroundColor: "rgba(255,255,255,0.15)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
  },
  logoText: {
    color: "white",
    fontWeight: "700",
    fontSize: "16px",
    letterSpacing: "-0.2px",
  },
  divider: {
    height: "1px",
    backgroundColor: "rgba(255,255,255,0.12)",
    margin: "0 4px 16px 4px",
  },
  nav: {
    display: "flex",
    flexDirection: "column",
    gap: "4px",
  },
  navItem: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    padding: "10px 12px",
    borderRadius: "10px",
    textDecoration: "none",
    position: "relative",
    transition: "background 0.15s",
  },
  navItemActive: {
    backgroundColor: "white",
  },
  iconBox: {
    width: "32px",
    height: "32px",
    borderRadius: "8px",
    backgroundColor: "rgba(255,255,255,0.1)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
  },
  iconBoxActive: {
    width: "32px",
    height: "32px",
    borderRadius: "8px",
    backgroundColor: "#dbeafe",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
  },
  navLabel: {
    color: "rgba(255,255,255,0.7)",
    fontSize: "14px",
    fontWeight: "500",
  },
  navLabelActive: {
    color: "#1e3a8a",
    fontSize: "14px",
    fontWeight: "700",
  },
  activePill: {
    position: "absolute",
    right: "12px",
    width: "6px",
    height: "6px",
    borderRadius: "50%",
    backgroundColor: "#2563eb",
  },
  spacer: {
    flex: 1,
  },
  logoutBtn: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    padding: "10px 12px",
    borderRadius: "10px",
    border: "none",
    backgroundColor: "#ef4444",
    cursor: "pointer",
    width: "100%",
    marginTop: "12px",
    boxShadow: "0 4px 12px rgba(239,68,68,0.4)",
  },
  logoutIconBox: {
    width: "32px",
    height: "32px",
    borderRadius: "8px",
    backgroundColor: "rgba(255,255,255,0.2)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
  },
  logoutLabel: {
    color: "white",
    fontSize: "14px",
    fontWeight: "700",
    fontFamily: "Inter, system-ui, sans-serif",
  },
};
