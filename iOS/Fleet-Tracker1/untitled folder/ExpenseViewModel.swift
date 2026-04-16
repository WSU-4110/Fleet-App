//
//  ExpenseViewModel.swift
//  Fleet-Tracker
//

import Foundation
import Combine
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class ExpenseViewModel: ObservableObject {
    var notifVM: NotificationViewModel?
    @Published var errorMessage: String?
    @Published var isSubmitting  = false
    @Published var submitSuccess = false

    private let db = Firestore.firestore()

    func submitExpense(
        businessId:   String,
        employeeUid:  String,
        employeeName: String,
        category:     ExpenseCategory,
        amount:       Double,
        note:         String,
        date:         Date,
        vehicleId:    String?,
        receiptImage: UIImage?,
        completion:   @escaping (Bool) -> Void
    ) {
        isSubmitting  = true
        errorMessage  = nil
        submitSuccess = false

        if let image = receiptImage {
            uploadReceipt(image: image) { [weak self] url in
                self?.writeExpense(
                    businessId:   businessId,
                    employeeUid:  employeeUid,
                    employeeName: employeeName,
                    category:     category,
                    amount:       amount,
                    note:         note,
                    date:         date,
                    vehicleId:    vehicleId,
                    receiptURL:   url,
                    completion:   completion
                )
            }
        } else {
            writeExpense(
                businessId:   businessId,
                employeeUid:  employeeUid,
                employeeName: employeeName,
                category:     category,
                amount:       amount,
                note:         note,
                date:         date,
                vehicleId:    vehicleId,
                receiptURL:   nil,
                completion:   completion
            )
        }
    }

    private func uploadReceipt(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.75),
              let uid  = Auth.auth().currentUser?.uid else {
            completion(nil); return
        }
        let ref = Storage.storage().reference()
            .child("receipts/\(uid)_\(UUID().uuidString).jpg")
        ref.putData(data, metadata: nil) { _, error in
            if error != nil { completion(nil); return }
            ref.downloadURL { url, _ in completion(url?.absoluteString) }
        }
    }

    private func writeExpense(
        businessId: String, employeeUid: String, employeeName: String,
        category: ExpenseCategory, amount: Double, note: String,
        date: Date, vehicleId: String?, receiptURL: String?,
        completion: @escaping (Bool) -> Void
    ) {
        let cal = Calendar.current
        let df  = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"; let dateStr = df.string(from: date)
        df.dateFormat = "HH:mm:ss";   let timeStr = df.string(from: date)
        df.dateFormat = "EEEE";       let dayStr  = df.string(from: date)
        df.dateFormat = "h:mm a";     let timeReadable = df.string(from: date)

        var data: [String: Any] = [
            "uid":           employeeUid,
            "employeeName":  employeeName,
            "businessId":    businessId,
            "category":      category.rawValue,
            "amount":        amount,
            "note":          note,
            "date":          Timestamp(date: date),
            "dateString":    dateStr,         // "2026-04-15"
            "timeString":    timeStr,         // "14:32:00"
            "timeReadable":  timeReadable,    // "2:32 PM"
            "dayOfWeek":     dayStr,          // "Wednesday"
            "week":          cal.component(.weekOfYear, from: date),
            "month":         cal.component(.month,       from: date),
            "year":          cal.component(.year,        from: date),
            "submittedAt":   FieldValue.serverTimestamp()
        ]
        if let vid = vehicleId   { data["vehicleId"]  = vid }
        if let url = receiptURL  { data["receiptURL"] = url }

        db.collection("businesses").document(businessId)
            .collection("expenses").addDocument(data: data) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isSubmitting  = false
                    self?.submitSuccess = error == nil
                    if let error {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        // Notify admin
                        self?.notifVM?.writeExpense(
                            businessId:   businessId,
                            employeeName: employeeName,
                            uid:          employeeUid,
                            category:     category.rawValue,
                            amount:       amount
                        )
                    }
                    completion(error == nil)
                }
            }
    }
}
