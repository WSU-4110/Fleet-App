import Sidebar from "./Sidebar";
import { useEffect,useState } from "react";
import { collection,onSnapshot } from "firebase/firestore";
import { db } from "./firebase";

export default function Dashboard(){

  const [trucks,setTrucks] = useState([]);

  useEffect(()=>{

    const unsub = onSnapshot(
      collection(db,"trucks"),
      snapshot =>{

        const data = snapshot.docs.map(doc=>({
          id:doc.id,
          ...doc.data()
        }));

        setTrucks(data);
      }
    );

    return unsub;

  },[]);

  return(
    <div style={styles.layout}>

      <Sidebar/>

      <div style={styles.main}>

        <h1 style={styles.title}>Fleet Dashboard</h1>

        <div style={styles.truckGrid}>

          {trucks.map(truck=>(
            <div key={truck.id} style={styles.truckCard}>
              <h3>{truck.name}</h3>
              <p>Status: {truck.status}</p>
              <p>Speed: {truck.speed}</p>
            </div>
          ))}

        </div>

      </div>
    </div>
  );
}

const styles={
  layout:{
    display:"flex",
    height:"100vh"
  },

  main:{
    flex:1,
    padding:"40px",
    background:"#f4f6fb"
  },

  title:{
    fontSize:"28px",
    fontWeight:"700"
  },

  truckGrid:{
    display:"grid",
    gridTemplateColumns:"repeat(auto-fill,minmax(240px,1fr))",
    gap:"20px",
    marginTop:"20px"
  },

  truckCard:{
    background:"white",
    padding:"20px",
    borderRadius:"12px",
    boxShadow:"0 10px 25px rgba(0,0,0,0.1)"
  }
};