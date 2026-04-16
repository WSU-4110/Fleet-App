import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./AuthContext";
import Login from "./Login";
import Layout from "./Layout";
import Home from "./pages/Home";
import Expenses from "./pages/Expenses";
import Employees from "./pages/Employees";
import Shifts from "./pages/Shifts";
import Signup from "./signup";
import ForgotPassword from "./ForgotPassword";
import MapPage from "./MapPage";

function App() {
  return (
    <AuthProvider>
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/" element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="expenses" element={<Expenses />} />
          <Route path="employees" element={<Employees />} />
          <Route path="shifts" element={<Shifts />} />
          <Route path="map" element={<MapPage />} />
          
        </Route>
      </Routes>
    </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
