import SwiftUI
import Firebase

@main
struct SklSwiftApp: App {
    // Создаем экземпляр PersistenceController как и раньше
    let persistenceController = PersistenceController.shared

    // Инициализируем Firebase
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
