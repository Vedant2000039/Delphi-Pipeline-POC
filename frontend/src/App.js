import React,{useState} from 'react';
export default function App() {
  const[count,setCount]=useState(0);

  return(
     <div style={{textAlign: "center", marginTop: 80}}>
      <h1>Simple Counter</h1>
      <div style={{fontSize: 64, margin: 20}}>{count}</div>
      <button onClick={()=>setCount(c=>c+1)} style={{padding: "10px 20px", fontSize: 18}}>Increment</button>
      <button onClick={()=>setCount(0)} style={{padding: "10px 20px", fontSize: 18, marginLeft: 12}}>Reset</button>
    </div>
  );
}