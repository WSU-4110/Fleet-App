import React from "react";

function VehicleTable({ vehicles }) {
  return (
    <table border="1">
      <thead>
        <tr>
          <th>Vehicle ID</th>
          <th>Location</th>
          <th>Status</th>
        </tr>
      </thead>

      <tbody>
        {vehicles.map((v, index) => (
          <tr key={index}>
            <td>{v.vehicleId}</td>
            <td>{v.location}</td>
            <td>{v.status}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export default VehicleTable;