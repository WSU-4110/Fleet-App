import Foundation
import FirebaseFirestore

/// Base class for all entities stored in Firebase
class Base {
    var id: String?
    var companyId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    /// Check if entity is soft-deleted
    var isDeleted: Bool {
        return deletedAt != nil
    }

    /// Mark entity as deleted (soft delete)
    func markAsDeleted() {
        deletedAt = Date()
    }



    /// Call this whenever updating the entity
    func onUpdate() {
        updatedAt = Date()
    }

    // MARK: - Firestore Mapping

    /// Populate Base fields from Firestore dictionary
    func populateBaseFields(from dictionary: [String: Any], id: String?) {
        self.id = id
        self.companyId = dictionary["companyId"] as? String
        if let created = dictionary["createdAt"] as? Timestamp {
            self.createdAt = created.dateValue()
        }
        if let updated = dictionary["updatedAt"] as? Timestamp {
            self.updatedAt = updated.dateValue()
        }
        if let deleted = dictionary["deletedAt"] as? Timestamp {
            self.deletedAt = deleted.dateValue()
        }
    }

    /// Initialize Base from Firestore dictionary
    convenience init(from dictionary: [String: Any], id: String? = nil) {
        self.init()
        self.populateBaseFields(from: dictionary, id: id)
    }

    func baseDict() -> [String: Any] {
        var dict: [String: Any] = [:]

        if let companyId = companyId { dict["companyId"] = companyId }
        if let createdAt = createdAt { dict["createdAt"] = createdAt }
        if let updatedAt = updatedAt { dict["updatedAt"] = updatedAt }
        if let deletedAt = deletedAt { dict["deletedAt"] = deletedAt }

        return dict
    }


    init() {
        let now = Date()
        createdAt = now
        updatedAt = now
    }
}
