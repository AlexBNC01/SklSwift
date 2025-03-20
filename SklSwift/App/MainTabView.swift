// файл MainTabView
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WarehouseView()
                .tabItem {
                    Label("Склад", systemImage: "house")
                }
            TransactionView()
                .tabItem {
                    Label("Приход/Расход", systemImage: "arrow.up.arrow.down")
                }
            HistoryView()
                .tabItem {
                    Label("История", systemImage: "clock")
                }
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
            AnalyticsView()
                .tabItem {
                    Label("Аналитика", systemImage: "chart.bar")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
