class Company: Base {
    var adminId: String
    var name: String
    var address: String
    var phone: String

    init(adminId: String, name: String, address: String, phone: String){
        self.name = name
        self.adminId = adminId
        self.address = address
        self.phone = phone
        super.init()
    }
    
    convenience init (from dict: [String: Any], id: String? = nill){
        let adminId = dict["adminId"] as? String ?? "Unknown"
        let name = dict["name"] as? String ?? "Unknown"
        let address = dict["address"] as? String ?? "Unknown"
        let phone = dict["phone"] as? String ?? "Unknown"
        self.init(adminId: adminId, name: name, address: address, phone: phone)
        super.populateBaseFields(from: dict, id: id)
    }


    func toDict() ->[String:Any]{
        var dict = basedict()
        dict["name"] = name
        dict["adminId"] = adminId
        dict["address"] = address
        dict["phone"] = phone

        return dict
    }
}