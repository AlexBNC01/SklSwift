import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @State private var isAuthenticated: Bool = Auth.auth().currentUser != nil
    @State private var showAuthSheet: Bool = false
    @State private var errorMessage: String? = nil
    
    // Следим за SessionManager
    @ObservedObject var sessionManager = SessionManager.shared

    var body: some View {
        NavigationView {
            List {
                // Раздел "Аккаунт"
                Section(header: Text("Аккаунт")) {
                    if !sessionManager.isGuest {
                        // Пользователь авторизован
                        HStack {
                            Text("Пользователь: \(sessionManager.currentUser?.email ?? "")")
                            Spacer()
                            Button("Выйти") {
                                sessionManager.signOut { result in
                                    switch result {
                                    case .success:
                                        isAuthenticated = false
                                    case .failure(let error):
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        // Гость
                        Button("Войти / Зарегистрироваться") {
                            showAuthSheet = true
                        }
                    }
                }
                
                // Существующий раздел настроек
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
                    NavigationLink(destination: DataBackupSettingsView()) {
                        Label("Резервное копирование", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
            .alert(isPresented: Binding<Bool>(
                get: { self.errorMessage != nil },
                set: { newValue in if !newValue { self.errorMessage = nil } }
            )) {
                Alert(title: Text("Ошибка"),
                      message: Text(errorMessage ?? ""),
                      dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showAuthSheet, onDismiss: {
                isAuthenticated = !sessionManager.isGuest
            }) {
                AuthViewWrapper()
            }
        }
        .onAppear {
            isAuthenticated = !sessionManager.isGuest
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
