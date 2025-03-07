//
//  FirestoreService.swift
//  SklSwift
//
import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    /// Сохраняет товар в коллекцию "products", включая дополнительные поля.
    func saveProduct(product: ProductItem, completion: @escaping (Error?) -> Void) {
        // Попытка извлечь дополнительные поля как словарь [String: String].
        var customFieldsData: [String: String] = [:]
        if let custom = product.customFields as? [String: String] {
            customFieldsData = custom
        }
        
        let productData: [String: Any] = [
            "id": product.id?.uuidString ?? UUID().uuidString,
            "name": product.name ?? "",
            "organization": product.organization ?? "",
            "price": product.price,
            "quantity": product.quantity,
            "category": product.category ?? "",
            "target": product.target ?? "",
            "barcode": product.barcode ?? "",
            "customFields": customFieldsData,  // Дополнительные поля
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("products").addDocument(data: productData) { error in
            completion(error)
        }
    }
}
