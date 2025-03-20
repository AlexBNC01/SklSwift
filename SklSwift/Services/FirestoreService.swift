//FirestoreService
import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import CoreData

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    /// Сохраняет или обновляет товар в Firestore для авторизованного пользователя.
    func saveOrUpdateProduct(product: ProductItem,
                             for user: User,
                             image: UIImage?,
                             completion: @escaping (Error?) -> Void) {
        let productId = product.id?.uuidString ?? UUID().uuidString
        
        if let image = image {
            uploadProductImage(image, productId: productId, user: user) { imageUrl in
                self.setProductData(product: product, imageUrl: imageUrl, for: user, completion: completion)
            }
        } else {
            self.setProductData(product: product, imageUrl: nil, for: user, completion: completion)
        }
    }
    
    private func uploadProductImage(_ image: UIImage,
                                    productId: String,
                                    user: User,
                                    completion: @escaping (String?) -> Void) {
        let imageRef = storage.reference().child("users/\(user.uid)/productImages/\(productId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Ошибка загрузки фото: \(error.localizedDescription)")
                completion(nil)
                return
            }
            imageRef.downloadURL { url, error in
                if let url = url {
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    private func setProductData(product: ProductItem,
                                imageUrl: String?,
                                for user: User,
                                completion: @escaping (Error?) -> Void) {
        let productId = product.id?.uuidString ?? UUID().uuidString
        
        var customFieldsData: [String: String] = [:]
        if let custom = product.customFields as? [String: String] {
            customFieldsData = custom
        }
        
        var data: [String: Any] = [
            "id": productId,
            "name": product.name ?? "",
            "organization": product.organization ?? "",
            "price": product.price,
            "quantity": product.quantity,
            "category": product.category ?? "",
            "target": product.target ?? "",
            "barcode": product.barcode ?? "",
            "customFields": customFieldsData,
            "timestamp": FieldValue.serverTimestamp()
        ]
        if let imageUrl = imageUrl {
            data["imageUrl"] = imageUrl
        }
        
        db.collection("users")
            .document(user.uid)
            .collection("products")
            .document(productId)
            .setData(data, merge: true) { error in
                completion(error)
            }
    }
    
    // MARK: - Fetch Products
    
    func fetchAllProducts(for user: User, completion: @escaping ([[String: Any]], Error?) -> Void) {
        db.collection("users")
            .document(user.uid)
            .collection("products")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                guard let docs = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                let items: [[String: Any]] = docs.map { doc in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    return data
                }
                completion(items, nil)
            }
    }
    
    // MARK: - Fetch Transactions
    
    func fetchAllTransactions(for user: User, completion: @escaping ([[String: Any]], Error?) -> Void) {
        db.collection("users")
            .document(user.uid)
            .collection("transactions")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                guard let docs = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                let items: [[String: Any]] = docs.map { doc in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    return data
                }
                completion(items, nil)
            }
    }
    
    // Сохраняем транзакцию в Firestore
    func saveTransaction(_ transaction: InventoryTransaction, for user: User, completion: @escaping (Error?) -> Void) {
        let transactionId = transaction.id?.uuidString ?? UUID().uuidString
        var data: [String: Any] = [
            "id": transactionId,
            "date": transaction.date ?? Date(),
            "type": transaction.type ?? "",
            "expenseQuantity": transaction.expenseQuantity,
            "expensePurpose": transaction.expensePurpose ?? "",
            "ownerId": user.uid,
            "timestamp": FieldValue.serverTimestamp()
        ]
        if let product = transaction.product, let productId = product.id?.uuidString {
            data["productId"] = productId
        }
        db.collection("users")
            .document(user.uid)
            .collection("transactions")
            .document(transactionId)
            .setData(data, merge: true) { error in
                completion(error)
            }
    }
    
    // MARK: - NEW: fetchLast25Transactions
    
    func fetchLast25Transactions(for user: User, completion: @escaping ([[String: Any]], Error?) -> Void) {
        db.collection("users")
            .document(user.uid)
            .collection("transactions")
            .order(by: "timestamp", descending: true)
            .limit(to: 25)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                guard let docs = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                let items: [[String: Any]] = docs.map { doc in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    return data
                }
                completion(items, nil)
            }
    }
}
