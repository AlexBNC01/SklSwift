//SessionManager
import SwiftUI
import FirebaseAuth
import CoreData

class SessionManager: ObservableObject {
    @Published var currentUser: User? = nil

    var isGuest: Bool {
        return currentUser == nil
    }
    
    static let shared = SessionManager()
    
    private init() {
        self.currentUser = Auth.auth().currentUser
    }
    
    // MARK: - Вход
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                self.currentUser = user
                
                let mainContext = PersistenceController.shared.container.viewContext
                
                // Удаляем гостевые
                let guestRequest: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
                guestRequest.predicate = NSPredicate(format: "ownerId == nil")
                if let guestProducts = try? mainContext.fetch(guestRequest) {
                    for product in guestProducts {
                        mainContext.delete(product)
                    }
                    do {
                        try mainContext.save()
                    } catch {
                        print("Ошибка удаления гостевых данных: \(error)")
                    }
                }
                
                // Загрузка товаров из Firestore
                FirestoreService.shared.fetchAllProducts(for: user) { productsData, fetchError in
                    if let fetchError = fetchError {
                        completion(.failure(fetchError))
                    } else {
                        self.saveProductsDataToMainStore(productsData, ownerId: user.uid)
                        // Загрузка транзакций
                        FirestoreService.shared.fetchAllTransactions(for: user) { transactionsData, transError in
                            if let transError = transError {
                                completion(.failure(transError))
                            } else {
                                self.saveTransactionsDataToMainStore(transactionsData, ownerId: user.uid)
                                DispatchQueue.main.async {
                                    mainContext.refreshAllObjects()
                                    completion(.success(user))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Выход
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        if let user = self.currentUser {
            do {
                try removeUserDataFromMainStore(ownerId: user.uid)
            } catch {
                completion(.failure(error))
                return
            }
        }
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Сохранение (теперь internal, не private)
    
    func saveProductsDataToMainStore(_ productsData: [[String: Any]], ownerId: String) {
        let mainContext = PersistenceController.shared.container.viewContext
        for dict in productsData {
            guard let idString = dict["id"] as? String,
                  let uuid = UUID(uuidString: idString) else { continue }
            let request: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            let product = (try? mainContext.fetch(request).first) ?? ProductItem(context: mainContext)
            product.id = uuid
            product.name = dict["name"] as? String
            product.organization = dict["organization"] as? String
            product.price = dict["price"] as? Double ?? 0
            product.quantity = dict["quantity"] as? Int64 ?? 0
            product.category = dict["category"] as? String
            product.target = dict["target"] as? String
            product.barcode = dict["barcode"] as? String
            product.ownerId = ownerId
            if let custom = dict["customFields"] as? [String: String] {
                product.customFields = custom as NSDictionary
            }
        }
        do {
            try mainContext.save()
        } catch {
            print("Ошибка сохранения товаров из Firebase: \(error)")
        }
    }
    
    func saveTransactionsDataToMainStore(_ transactionsData: [[String: Any]], ownerId: String) {
        let mainContext = PersistenceController.shared.container.viewContext
        for dict in transactionsData {
            guard let idString = dict["id"] as? String,
                  let uuid = UUID(uuidString: idString) else { continue }
            let request: NSFetchRequest<InventoryTransaction> = InventoryTransaction.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            let transaction = (try? mainContext.fetch(request).first) ?? InventoryTransaction(context: mainContext)
            transaction.id = uuid
            transaction.date = dict["date"] as? Date ?? Date()
            transaction.type = dict["type"] as? String
            transaction.expenseQuantity = dict["expenseQuantity"] as? Int64 ?? 0
            transaction.expensePurpose = dict["expensePurpose"] as? String
            transaction.ownerId = ownerId
            if let productIdString = dict["productId"] as? String,
               let productId = UUID(uuidString: productIdString) {
                let productRequest: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
                productRequest.predicate = NSPredicate(format: "id == %@", productId as CVarArg)
                if let product = try? mainContext.fetch(productRequest).first {
                    transaction.product = product
                }
            }
        }
        do {
            try mainContext.save()
        } catch {
            print("Ошибка сохранения транзакций из Firebase: \(error)")
        }
    }
    
    // MARK: - Удаление данных
    
    private func removeUserDataFromMainStore(ownerId: String) throws {
        let mainContext = PersistenceController.shared.container.viewContext
        
        let productRequest: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
        productRequest.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        let userItems = try mainContext.fetch(productRequest)
        for item in userItems {
            mainContext.delete(item)
        }
        try mainContext.save()
        
        let transactionRequest: NSFetchRequest<InventoryTransaction> = InventoryTransaction.fetchRequest()
        transactionRequest.predicate = NSPredicate(format: "ownerId == %@", ownerId)
        let userTransactions = try mainContext.fetch(transactionRequest)
        for t in userTransactions {
            mainContext.delete(t)
        }
        try mainContext.save()
    }
}
