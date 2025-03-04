//SettingsView
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Настройки приложения")) {
                    NavigationLink(destination: ProductFieldsSettingsView()) {
                        Label("Поля для товара", systemImage: "square.and.pencil")
                    }
                    NavigationLink(destination: CategoryOptionsSettingsView()) {
                        Label("Опции категории", systemImage: "list.bullet")
                    }
                    NavigationLink(destination: TechniqueOptionsSettingsView()) {
                        Label("Опции техники", systemImage: "list.bullet")
                    }
                    NavigationLink(destination: ExportHistoryView()) {
                        Label("Экспорт истории", systemImage: "tray.and.arrow.down")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
