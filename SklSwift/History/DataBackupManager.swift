// databackupmanager
import Foundation
import CoreData
import UIKit

// MARK: - Структуры для кодируемого представления данных

struct ProductBackup: Codable {
    let id: UUID
    let name: String?
    let organization: String?
    let price: Double
    let quantity: Int64
    let category: String?
    let target: String?
    let barcode: String?
    let photo: String?         // Фото товара в виде Base64 строки
    let customFields: [String: String]?
    let ownerId: String?
    // Если требуется сохранять связь с контейнером, можно добавить containerId (опционально)
    // let containerId: UUID?
}

struct TransactionBackup: Codable {
    let id: UUID
    let date: Date
    let type: String?
    let expenseQuantity: Int64
    let expensePurpose: String?
    let productId: UUID?       // Идентификатор товара, с которым связана транзакция
}

struct ContainerBackup: Codable {
    let id: UUID
    let name: String?
}

struct BackupData: Codable {
    let products: [ProductBackup]
    let transactions: [TransactionBackup]
    let containers: [ContainerBackup]
}

// MARK: - Менеджер экспорта/импорта данных

class DataBackupManager {
    
    /// Экспортирует все данные (товары, транзакции, контейнеры) в JSON-файл и возвращает URL на него.
    static func exportData() -> URL? {
        let context = PersistenceController.shared.container.viewContext
        do {
            let products = try context.fetch(ProductItem.fetchRequest() as NSFetchRequest<ProductItem>)
            let transactions = try context.fetch(InventoryTransaction.fetchRequest() as NSFetchRequest<InventoryTransaction>)
            let containers = try context.fetch(WarehouseContainer.fetchRequest() as NSFetchRequest<WarehouseContainer>)
            
            // Преобразуем товары в кодируемую структуру
            let productBackups: [ProductBackup] = products.map { product in
                let photoString: String?
                if let photoData = product.photo {
                    photoString = photoData.base64EncodedString()
                } else {
                    photoString = nil
                }
                var custom: [String: String]? = nil
                if let dict = product.customFields as? [String: String] {
                    custom = dict
                }
                return ProductBackup(
                    id: product.id ?? UUID(),
                    name: product.name,
                    organization: product.organization,
                    price: product.price,
                    quantity: product.quantity,
                    category: product.category,
                    target: product.target,
                    barcode: product.barcode,
                    photo: photoString,
                    customFields: custom,
                    ownerId: product.ownerId
                    // Если используется связь с контейнером, можно добавить: containerId: product.container?.id
                )
            }
            
            // Преобразуем транзакции (историю операций)
            let transactionBackups: [TransactionBackup] = transactions.map { transaction in
                return TransactionBackup(
                    id: transaction.id ?? UUID(),
                    date: transaction.date ?? Date(),
                    type: transaction.type,
                    expenseQuantity: transaction.expenseQuantity,
                    expensePurpose: transaction.expensePurpose,
                    productId: transaction.product?.id
                )
            }
            
            // Преобразуем контейнеры
            let containerBackups: [ContainerBackup] = containers.map { container in
                return ContainerBackup(
                    id: container.id ?? UUID(),
                    name: container.name
                )
            }
            
            let backupData = BackupData(products: productBackups,
                                        transactions: transactionBackups,
                                        containers: containerBackups)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(backupData)
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "Backup_\(Date().timeIntervalSince1970).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Ошибка экспорта данных: \(error)")
            return nil
        }
    }
    
    /// Импортирует данные из указанного JSON-файла. Новые записи добавляются, существующие (с одинаковым id) обновляются.
    static func importData(from url: URL) {
        let context = PersistenceController.shared.container.viewContext
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backupData = try decoder.decode(BackupData.self, from: data)
            
            // 1. Импортируем контейнеры – они могут понадобиться для связи с товарами
            for containerBackup in backupData.containers {
                let fetchRequest: NSFetchRequest<WarehouseContainer> = WarehouseContainer.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", containerBackup.id as CVarArg)
                if let existing = try context.fetch(fetchRequest).first {
                    existing.name = containerBackup.name
                } else {
                    let newContainer = WarehouseContainer(context: context)
                    newContainer.id = containerBackup.id
                    newContainer.name = containerBackup.name
                }
            }
            
            // 2. Импортируем товары
            for productBackup in backupData.products {
                let fetchRequest: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", productBackup.id as CVarArg)
                let product: ProductItem
                if let existing = try context.fetch(fetchRequest).first {
                    product = existing
                } else {
                    product = ProductItem(context: context)
                    product.id = productBackup.id
                }
                product.name = productBackup.name
                product.organization = productBackup.organization
                product.price = productBackup.price
                product.quantity = productBackup.quantity
                product.category = productBackup.category
                product.target = productBackup.target
                product.barcode = productBackup.barcode
                if let photoString = productBackup.photo,
                   let photoData = Data(base64Encoded: photoString) {
                    product.photo = photoData
                }
                if let custom = productBackup.customFields {
                    product.customFields = custom as NSDictionary
                }
                product.ownerId = productBackup.ownerId
                
                // Если используется связь с контейнером и в backup добавили containerId,
                // можно попытаться найти соответствующий WarehouseContainer и установить его.
                /*
                if let containerId = productBackup.containerId {
                    let containerRequest: NSFetchRequest<WarehouseContainer> = WarehouseContainer.fetchRequest()
                    containerRequest.predicate = NSPredicate(format: "id == %@", containerId as CVarArg)
                    if let container = try context.fetch(containerRequest).first {
                        product.container = container
                    }
                }
                */
            }
            
            // 3. Импортируем транзакции (историю)
            for transactionBackup in backupData.transactions {
                let fetchRequest: NSFetchRequest<InventoryTransaction> = InventoryTransaction.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", transactionBackup.id as CVarArg)
                let transaction: InventoryTransaction
                if let existing = try context.fetch(fetchRequest).first {
                    transaction = existing
                } else {
                    transaction = InventoryTransaction(context: context)
                    transaction.id = transactionBackup.id
                }
                transaction.date = transactionBackup.date
                transaction.type = transactionBackup.type
                transaction.expenseQuantity = transactionBackup.expenseQuantity
                transaction.expensePurpose = transactionBackup.expensePurpose
                
                // Устанавливаем связь с товаром по productId
                if let productId = transactionBackup.productId {
                    let productFetch: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
                    productFetch.predicate = NSPredicate(format: "id == %@", productId as CVarArg)
                    if let relatedProduct = try context.fetch(productFetch).first {
                        transaction.product = relatedProduct
                    }
                }
            }
            
            try context.save()
            print("Импорт данных выполнен успешно.")
        } catch {
            print("Ошибка импорта данных: \(error)")
        }
    }
}
