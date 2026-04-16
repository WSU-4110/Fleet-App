class Vehicle: Base {
    var vin: String
    var make: String
    var model: String
    var year: Int
    var color: String?
    var mileage: Int = 0

    init(vin: String, make: String, model: String, year: Int, color: String?, mileage: Int){
        self.vin = vin
        self.make = make
        self.model = model
        self.year = year
        self.mileage = mileage
        self.color = color ?? "Color not set"

        super.init()
    }


    convenience init(from dict: [String: Any], id: String? = nil) {
        let vin = dict["vin"] as? String ?? "No VIN"
        let make = dict["make"] as? String ?? "Unknown Make"
        let model = dict["model"] as? String ?? "Unknown Model"
        let year = dict["year"] as? Int ?? 0
        let color = dict["color"] as? String ?? "Unknown color"
        let mileage = dict["mileage"] as? Int ?? 0

        self.init(vin: vin, make: make, model: model, year: year, color: color, mileage: mileage)
        super.populateBaseFields(from: dict, id: id)
    }

    func toDict() -> [String : Any] {
        var dict = baseDict()

        dict["vin"] = vin
        dict["make"] = make
        dict["model"] = model
        dict["year"] = year
        dict["color"] = color
        dict["mileage"] = mileage

        return dict
    }
}