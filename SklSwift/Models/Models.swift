import Foundation
import CoreData

@objc(WarehouseContainer)
public class WarehouseContainer: NSManagedObject { }

extension WarehouseContainer {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WarehouseContainer> {
        NSFetchRequest<WarehouseContainer>(entityName: "WarehouseContainer")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var products: NSSet?
}

@objc(ProductItem)
public class ProductItem: NSManagedObject { }

extension ProductItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductItem> {
        NSFetchRequest<ProductItem>(entityName: "ProductItem")
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
    @NSManaged public var ownerId: String?  // Для идентификации владельца (uid)
    @NSManaged public var container: WarehouseContainer?
}

@objc(InventoryTransaction)
public class InventoryTransaction: NSManagedObject { }

extension InventoryTransaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InventoryTransaction> {
        NSFetchRequest<InventoryTransaction>(entityName: "InventoryTransaction")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var expenseQuantity: Int64
    @NSManaged public var expensePurpose: String?
    @NSManaged public var product: ProductItem?
    // Новое поле для идентификации владельца транзакции
    @NSManaged public var ownerId: String?
}
