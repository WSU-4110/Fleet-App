class User: Base {
    var accessId: String? // TODO As soon as accessId generation is implemented, change this to NON Optional
    var firstName: String
    var lastName: String
    var phone: String
    var jobTitle: JobTitle? // this is optional but still good to have
    var role: Role


    init(firstName: String, lastName: String, phone: String, role: Role, jobTitle: JobTitle?){
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.accessId = nil  //TODO URGENT - replace this with generateAccessId from util folder when it is ready
        self.role = role

        self.jobTitle = jobTitle ?? .other
        super.init()
    }

    convenience init(from dictionary: [String: Any], id: String? = nil) {
        let firstName = dictionary["firstName"] as? String ?? "Unknown"
        let lastName = dictionary["lastName"] as? String ?? "Unknown"
        let phone = dictionary["phone"] as? String ?? "No phone number"

        self.init(firstName: firstName, lastName: lastName, phone: phone)

        self.accessId = dictionary["accessId"] as? String

        super.populateBaseFields(from: dictionary, id: id)
    }


    func toDict() -> [String: Any] {
        var dict = baseDict()

        if let accessId = accessId {
            dict["accessId"] = accessId
        } //TODO change it to regular field not optional when generate access id is fixed

        dict["firstName"] = firstName
        dict["lastName"] = lastName
        dict["phone"] = phone

        return dict
    }

     }


