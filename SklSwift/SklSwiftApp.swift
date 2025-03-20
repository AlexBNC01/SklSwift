// файл SklSwiftApp
import SwiftUI
import Firebase

@main
struct SklSwiftApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Если хотим, можем передавать SessionManager как environmentObject
                .environmentObject(SessionManager.shared)
        }
    }
}
