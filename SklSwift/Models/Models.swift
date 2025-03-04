//
//  Models.swift
//  SklSwift
//
//  Описание классов и их свойств Core Data.
//

import Foundation
import CoreData

// MARK: - WarehouseContainer
@objc(WarehouseContainer)
public class WarehouseContainer: NSManagedObject { }

extension WarehouseContainer {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WarehouseContainer> {
        return NSFetchRequest<WarehouseContainer>(entityName: "WarehouseContainer")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    
    @NSManaged public var products: NSSet?
}

// MARK: - ProductItem
@objc(ProductItem)
public class ProductItem: NSManagedObject { }

extension ProductItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductItem> {
        return NSFetchRequest<ProductItem>(entityName: "ProductItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var organization: String?
    @NSManaged public var price: Double
    @NSManaged public var quantity: Int64
    @NSManaged public var category: String?
    @NSManaged public var target: String?
    @NSManaged public var barcode: String?
    @NSManaged public var photo: Data?
    @NSManaged public var customFields: NSObject?
    
    @NSManaged public var container: WarehouseContainer?
}

// MARK: - InventoryTransaction
@objc(InventoryTransaction)
public class InventoryTransaction: NSManagedObject { }

extension InventoryTransaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InventoryTransaction> {
        return NSFetchRequest<InventoryTransaction>(entityName: "InventoryTransaction")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    
    // Новые поля для списания
    @NSManaged public var expenseQuantity: Int64
    @NSManaged public var expensePurpose: String?
    
    @NSManaged public var product: ProductItem?
}
