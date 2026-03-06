import React, { useState } from "react";
import VehicleTable from "./VehicleTable";

import FleetModel from "../Model/FleetModel";
import FleetController from "../Controller/FleetController";
import Vehicle from "../Model/Vehicle";

const model = new FleetModel();
const controller = new FleetController(model);

controller.addVehicle(new Vehicle("V101", "Detroit", "Active"));
controller.addVehicle(new Vehicle("V102", "Chicago", "Idle"));

function DashboardView() {

  const [vehicles, setVehicles] = useState(controller.getVehicles());

  const refreshVehicles = () => {
    setVehicles([...controller.getVehicles()]);
  };

  return (
    <div>
      <h1>Fleet Dashboard</h1>

      <VehicleTable vehicles={vehicles} />

      <button onClick={refreshVehicles}>
        Refresh
      </button>
    </div>
  );
}

export default DashboardView;