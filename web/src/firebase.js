import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyB_xnPK0F8ZKTk_6V_896-MmC7JNg23Zuk",
  authDomain: "fleet-app-28cf5.firebaseapp.com",
  projectId: "fleet-app-28cf5",
  storageBucket: "fleet-app-28cf5.firebasestorage.app",
  messagingSenderId: "911414614308",
  appId: "1:911414614308:web:e37440cbc31aa17cec3bb1",
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
