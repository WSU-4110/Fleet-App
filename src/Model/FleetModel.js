class FleetModel {
  constructor() {
    this.vehicles = [];
  }

  addVehicle(vehicle) {
    this.vehicles.push(vehicle);
  }

  getVehicles() {
    return this.vehicles;
  }

  updateVehicleStatus(vehicleId, status) {
    const vehicle = this.vehicles.find(v => v.vehicleId === vehicleId);
    if (vehicle) {
      vehicle.status = status;
    }
  }
}

export default FleetModel;