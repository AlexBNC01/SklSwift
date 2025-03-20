// файл GuestPersistenceController
import CoreData

final class GuestPersistenceController {
    static let shared = GuestPersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Используем ту же модель, что и в основном хранилище
        container = NSPersistentContainer(name: "SklSwiftGuest", managedObjectModel: PersistenceController.model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let storeDescription = container.persistentStoreDescriptions.first {
                let storeURL = URL.documentsDirectory.appendingPathComponent("GuestSklSwift.sqlite")
                storeDescription.url = storeURL
            }
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Не удалось загрузить гостевое хранилище: \(error)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
