import { Outlet } from "react-router-dom";
import Sidebar from "./Sidebar";

export default function Layout() {
  return (
    <div style={{ display: "flex", height: "100vh", fontFamily: "Inter, system-ui, sans-serif" }}>
      <Sidebar />
      <main style={{ flex: 1, backgroundColor: "#f4f6fb", overflowY: "auto", padding: "40px" }}>
        <Outlet />
      </main>
    </div>
  );
}
