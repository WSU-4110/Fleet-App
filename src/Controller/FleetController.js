class FleetController {
  constructor(model) {
    this.model = model;
  }

  addVehicle(vehicle) {
    this.model.addVehicle(vehicle);
  }

  getVehicles() {
    return this.model.getVehicles();
  }

  updateVehicleStatus(vehicleId, status) {
    this.model.updateVehicleStatus(vehicleId, status);
  }
}

export default FleetController;