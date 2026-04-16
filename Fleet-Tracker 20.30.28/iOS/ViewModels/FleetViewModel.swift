//
//  FleetViewModel.swift
//  Fleet-Tracker
//

import Foundation
import Combine
import UIKit
import FirebaseFirestore
import FirebaseStorage

final class FleetViewModel: ObservableObject {
    @Published var vehicles: [VehicleModel] = []
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var businessId: String?

    // ── Watch ─────────────────────────────────────────────────────────────────

    func startWatching(businessId: String) {
        listener?.remove()  // remove old listener first
        self.businessId = businessId
        listener = db.collection("businesses").document(businessId)
            .collection("vehicles")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error { print("Fleet listener: \(error)"); return }
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.vehicles = docs.compactMap { doc in
                        let d = doc.data()
                        guard let make  = d["make"]  as? String,
                              let model = d["model"] as? String else { return nil }
                        return VehicleModel(
                            id:           doc.documentID,
                            businessId:   businessId,
                            make:         make,
                            model:        model,
                            year:         d["year"]         as? String ?? "",
                            licensePlate: d["licensePlate"] as? String ?? "",
                            emoji:        d["emoji"]        as? String ?? "🚗",
                            photoURL:     d["photoURL"]     as? String
                        )
                    }
                    .sorted { $0.displayName < $1.displayName }
                }
            }
    }

    func stopWatching() { listener?.remove() }

    // ── Add vehicle ───────────────────────────────────────────────────────────

    func addVehicle(make: String, model: String, year: String,
                    licensePlate: String, emoji: String,
                    photo: UIImage?,
                    completion: @escaping (Error?) -> Void) {
        guard let bid = businessId else {
            print("FleetViewModel.addVehicle: businessId is nil — call startWatching first")
            DispatchQueue.main.async { completion(nil) }   // unblock the UI
            return
        }

        if let photo {
            uploadVehiclePhoto(photo, businessId: bid) { [weak self] photoURL in
                self?.writeVehicle(bid: bid, make: make, model: model, year: year,
                                   licensePlate: licensePlate, emoji: emoji,
                                   photoURL: photoURL, completion: completion)
            }
        } else {
            writeVehicle(bid: bid, make: make, model: model, year: year,
                         licensePlate: licensePlate, emoji: emoji,
                         photoURL: nil, completion: completion)
        }
    }

    private func uploadVehiclePhoto(_ image: UIImage, businessId: String,
                                    completion: @escaping (String?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            completion(nil); return
        }
        let ref = Storage.storage().reference()
            .child("vehiclePhotos/\(businessId)_\(UUID().uuidString).jpg")
        ref.putData(data, metadata: nil) { _, error in
            if error != nil { completion(nil); return }
            ref.downloadURL { url, _ in completion(url?.absoluteString) }
        }
    }

    private func writeVehicle(bid: String, make: String, model: String,
                               year: String, licensePlate: String, emoji: String,
                               photoURL: String?, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "make":         make,
            "model":        model,
            "year":         year,
            "licensePlate": licensePlate.uppercased(),
            "emoji":        emoji,
            "createdAt":    FieldValue.serverTimestamp()
        ]
        if let url = photoURL { data["photoURL"] = url }

        db.collection("businesses").document(bid)
            .collection("vehicles").addDocument(data: data) { error in
                DispatchQueue.main.async { completion(error) }
            }
    }

    // ── Update ───────────────────────────────────────────────────────────────

    func updateVehicle(_ vehicle: VehicleModel, make: String, model: String,
                       year: String, licensePlate: String, emoji: String,
                       photo: UIImage?,
                       completion: @escaping (Error?) -> Void) {
        guard let bid = businessId else {
            print("FleetViewModel.addVehicle: businessId is nil — call startWatching first")
            DispatchQueue.main.async { completion(nil) }   // unblock the UI
            return
        }

        if let photo {
            // Delete old photo if there was one
            if let oldURL = vehicle.photoURL {
                Storage.storage().reference(forURL: oldURL).delete(completion: nil)
            }
            uploadVehiclePhoto(photo, businessId: bid) { [weak self] photoURL in
                self?.writeUpdate(bid: bid, vehicleId: vehicle.id, make: make, model: model,
                                  year: year, licensePlate: licensePlate, emoji: emoji,
                                  photoURL: photoURL, completion: completion)
            }
        } else {
            writeUpdate(bid: bid, vehicleId: vehicle.id, make: make, model: model,
                        year: year, licensePlate: licensePlate, emoji: emoji,
                        photoURL: vehicle.photoURL, completion: completion)
        }
    }

    private func writeUpdate(bid: String, vehicleId: String, make: String, model: String,
                              year: String, licensePlate: String, emoji: String,
                              photoURL: String?, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "make":         make,
            "model":        model,
            "year":         year,
            "licensePlate": licensePlate.uppercased(),
            "emoji":        emoji
        ]
        if let url = photoURL { data["photoURL"] = url }
        else                  { data["photoURL"] = NSNull() }

        db.collection("businesses").document(bid)
            .collection("vehicles").document(vehicleId)
            .updateData(data) { error in
                DispatchQueue.main.async { completion(error) }
            }
    }

    // ── Delete ────────────────────────────────────────────────────────────────

    func deleteVehicle(_ vehicle: VehicleModel) {
        guard let bid = businessId else { return }
        // Delete photo from Storage if one exists
        if let url = vehicle.photoURL {
            Storage.storage().reference(forURL: url).delete(completion: nil)
        }
        db.collection("businesses").document(bid)
            .collection("vehicles").document(vehicle.id).delete()
    }
}
