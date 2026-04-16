import { createContext, useContext, useEffect, useState } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { collection, query, where, getDocs } from "firebase/firestore";
import { auth, db } from "./firebase";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(undefined); // undefined = still loading
  const [businessId, setBusinessId] = useState(null);

  useEffect(() => {
    return onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser);
      if (!firebaseUser) {
        setBusinessId(null);
        return;
      }
      try {
        const snap = await getDocs(
          query(collection(db, "businesses"), where("ownerId", "==", firebaseUser.uid))
        );
        setBusinessId(snap.empty ? null : snap.docs[0].id);
      } catch {
        setBusinessId(null);
      }
    });
  }, []);

  return (
    <AuthContext.Provider value={{ user, businessId }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
