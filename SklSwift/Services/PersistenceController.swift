//PersistenceController
import CoreData
import UIKit

final class PersistenceController {
    static let shared = PersistenceController()
    
    // Создаём единую модель для всего приложения
    static let model: NSManagedObjectModel = {
        return createManagedObjectModel()
    }()
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SklSwift", managedObjectModel: PersistenceController.model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let storeDescription = container.persistentStoreDescriptions.first {
                let storeURL = URL.documentsDirectory.appendingPathComponent("SklSwift.sqlite")
                storeDescription.url = storeURL
            }
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Не удалось загрузить хранилище: \(error)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Получаем имя модуля (обычно имя приложения)
        let moduleName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        
        // WarehouseContainer entity
        let warehouseEntity = NSEntityDescription()
        warehouseEntity.name = "WarehouseContainer"
        warehouseEntity.managedObjectClassName = "\(moduleName).WarehouseContainer"
        
        let warehouseIdAttr = NSAttributeDescription()
        warehouseIdAttr.name = "id"
        warehouseIdAttr.attributeType = .UUIDAttributeType
        warehouseIdAttr.isOptional = false
        
        let warehouseNameAttr = NSAttributeDescription()
        warehouseNameAttr.name = "name"
        warehouseNameAttr.attributeType = .stringAttributeType
        warehouseNameAttr.isOptional = false
        
        warehouseEntity.properties = [warehouseIdAttr, warehouseNameAttr]
        
        // ProductItem entity
        let productEntity = NSEntityDescription()
        productEntity.name = "ProductItem"
        productEntity.managedObjectClassName = "\(moduleName).ProductItem"
        
        let productIdAttr = NSAttributeDescription()
        productIdAttr.name = "id"
        productIdAttr.attributeType = .UUIDAttributeType
        productIdAttr.isOptional = false
        
        let productNameAttr = NSAttributeDescription()
        productNameAttr.name = "name"
        productNameAttr.attributeType = .stringAttributeType
        productNameAttr.isOptional = false
        
        let organizationAttr = NSAttributeDescription()
        organizationAttr.name = "organization"
        organizationAttr.attributeType = .stringAttributeType
        organizationAttr.isOptional = false
        
        let priceAttr = NSAttributeDescription()
        priceAttr.name = "price"
        priceAttr.attributeType = .doubleAttributeType
        priceAttr.isOptional = false
        
        let quantityAttr = NSAttributeDescription()
        quantityAttr.name = "quantity"
        quantityAttr.attributeType = .integer64AttributeType
        quantityAttr.isOptional = false
        quantityAttr.defaultValue = 0
        
        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isOptional = false
        
        let targetAttr = NSAttributeDescription()
        targetAttr.name = "target"
        targetAttr.attributeType = .stringAttributeType
        targetAttr.isOptional = false
        
        let barcodeAttr = NSAttributeDescription()
        barcodeAttr.name = "barcode"
        barcodeAttr.attributeType = .stringAttributeType
        barcodeAttr.isOptional = false
        
        let photoAttr = NSAttributeDescription()
        photoAttr.name = "photo"
        photoAttr.attributeType = .binaryDataAttributeType
        photoAttr.isOptional = true
        photoAttr.allowsExternalBinaryDataStorage = true
        
        let customFieldsAttr = NSAttributeDescription()
        customFieldsAttr.name = "customFields"
        customFieldsAttr.attributeType = .transformableAttributeType
        customFieldsAttr.isOptional = true
        customFieldsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        
        let productOwnerIdAttr = NSAttributeDescription()
        productOwnerIdAttr.name = "ownerId"
        productOwnerIdAttr.attributeType = .stringAttributeType
        productOwnerIdAttr.isOptional = true
        
        productEntity.properties = [
            productIdAttr,
            productNameAttr,
            organizationAttr,
            priceAttr,
            quantityAttr,
            categoryAttr,
            targetAttr,
            barcodeAttr,
            photoAttr,
            customFieldsAttr,
            productOwnerIdAttr
        ]
        
        // InventoryTransaction entity
        let transactionEntity = NSEntityDescription()
        transactionEntity.name = "InventoryTransaction"
        transactionEntity.managedObjectClassName = "\(moduleName).InventoryTransaction"
        
        let transactionIdAttr = NSAttributeDescription()
        transactionIdAttr.name = "id"
        transactionIdAttr.attributeType = .UUIDAttributeType
        transactionIdAttr.isOptional = false
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        
        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = false
        
        let expenseQuantityAttr = NSAttributeDescription()
        expenseQuantityAttr.name = "expenseQuantity"
        expenseQuantityAttr.attributeType = .integer64AttributeType
        expenseQuantityAttr.isOptional = false
        expenseQuantityAttr.defaultValue = 0
        
        let expensePurposeAttr = NSAttributeDescription()
        expensePurposeAttr.name = "expensePurpose"
        expensePurposeAttr.attributeType = .stringAttributeType
        expensePurposeAttr.isOptional = true
        
        // Атрибут ownerId для транзакций
        let transactionOwnerIdAttr = NSAttributeDescription()
        transactionOwnerIdAttr.name = "ownerId"
        transactionOwnerIdAttr.attributeType = .stringAttributeType
        transactionOwnerIdAttr.isOptional = true
        
        // Новый атрибут productName для денормализации названия товара
        let transactionProductNameAttr = NSAttributeDescription()
        transactionProductNameAttr.name = "productName"
        transactionProductNameAttr.attributeType = .stringAttributeType
        transactionProductNameAttr.isOptional = true
        
        transactionEntity.properties = [
            transactionIdAttr,
            dateAttr,
            typeAttr,
            expenseQuantityAttr,
            expensePurposeAttr,
            transactionOwnerIdAttr,
            transactionProductNameAttr
        ]
        
        // Связь Transaction -> ProductItem
        let transactionProductRelationship = NSRelationshipDescription()
        transactionProductRelationship.name = "product"
        transactionProductRelationship.destinationEntity = productEntity
        transactionProductRelationship.minCount = 0
        transactionProductRelationship.maxCount = 1
        transactionProductRelationship.deleteRule = .nullifyDeleteRule
        transactionProductRelationship.isOptional = true
        transactionEntity.properties.append(transactionProductRelationship)
        
        // Связь WarehouseContainer <-> ProductItem
        let productsRelationship = NSRelationshipDescription()
        productsRelationship.name = "products"
        productsRelationship.destinationEntity = productEntity
        productsRelationship.minCount = 0
        productsRelationship.maxCount = 0
        productsRelationship.deleteRule = .nullifyDeleteRule
        productsRelationship.isOptional = true
        productsRelationship.isOrdered = false
        
        let containerRelationship = NSRelationshipDescription()
        containerRelationship.name = "container"
        containerRelationship.destinationEntity = warehouseEntity
        containerRelationship.minCount = 0
        containerRelationship.maxCount = 1
        containerRelationship.deleteRule = .nullifyDeleteRule
        containerRelationship.isOptional = true
        
        productsRelationship.inverseRelationship = containerRelationship
        containerRelationship.inverseRelationship = productsRelationship
        
        warehouseEntity.properties.append(productsRelationship)
        productEntity.properties.append(containerRelationship)
        
        model.entities = [warehouseEntity, productEntity, transactionEntity]
        return model
    }
}
