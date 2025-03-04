//
//  PersistenceController.swift
//  SklSwift
//
//  Программное создание модели Core Data и настройка NSPersistentContainer.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        container = NSPersistentContainer(name: "SklSwift", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
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
        
        // MARK: - Сущность WarehouseContainer
        let warehouseEntity = NSEntityDescription()
        warehouseEntity.name = "WarehouseContainer"
        // Важно: имя класса совпадает с @objc(...) в Models.swift
        warehouseEntity.managedObjectClassName = "SklSwift.WarehouseContainer"
        
        let warehouseIdAttr = NSAttributeDescription()
        warehouseIdAttr.name = "id"
        warehouseIdAttr.attributeType = .UUIDAttributeType
        warehouseIdAttr.isOptional = false
        
        let warehouseNameAttr = NSAttributeDescription()
        warehouseNameAttr.name = "name"
        warehouseNameAttr.attributeType = .stringAttributeType
        warehouseNameAttr.isOptional = false
        
        warehouseEntity.properties = [warehouseIdAttr, warehouseNameAttr]
        
        // MARK: - Сущность ProductItem
        let productEntity = NSEntityDescription()
        productEntity.name = "ProductItem"
        // Имя класса совпадает с @objc(ProductItem) в Models.swift
        productEntity.managedObjectClassName = "SklSwift.ProductItem"
        
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
            customFieldsAttr
        ]
        
        // MARK: - Сущность InventoryTransaction
        let transactionEntity = NSEntityDescription()
        transactionEntity.name = "InventoryTransaction"
        // Имя класса совпадает с @objc(InventoryTransaction) в Models.swift
        transactionEntity.managedObjectClassName = "SklSwift.InventoryTransaction"
        
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
        
        // Новые поля для списания
        let expenseQuantityAttr = NSAttributeDescription()
        expenseQuantityAttr.name = "expenseQuantity"
        expenseQuantityAttr.attributeType = .integer64AttributeType
        expenseQuantityAttr.isOptional = false
        expenseQuantityAttr.defaultValue = 0
        
        let expensePurposeAttr = NSAttributeDescription()
        expensePurposeAttr.name = "expensePurpose"
        expensePurposeAttr.attributeType = .stringAttributeType
        expensePurposeAttr.isOptional = true
        
        transactionEntity.properties = [
            transactionIdAttr,
            dateAttr,
            typeAttr,
            expenseQuantityAttr,
            expensePurposeAttr
        ]
        
        // Отношение InventoryTransaction.product -> ProductItem
        let transactionProductRelationship = NSRelationshipDescription()
        transactionProductRelationship.name = "product"
        transactionProductRelationship.destinationEntity = productEntity
        transactionProductRelationship.minCount = 0
        transactionProductRelationship.maxCount = 1
        transactionProductRelationship.deleteRule = .nullifyDeleteRule
        transactionProductRelationship.isOptional = true
        
        transactionEntity.properties.append(transactionProductRelationship)
        
        // MARK: - Отношения WarehouseContainer <-> ProductItem
        let productsRelationship = NSRelationshipDescription()
        productsRelationship.name = "products"
        productsRelationship.destinationEntity = productEntity
        productsRelationship.minCount = 0
        productsRelationship.maxCount = 0  // 0 = неограниченное число
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
