//файл AuthViewWrapper
import SwiftUI
import FirebaseAuth

struct AuthViewWrapper: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoginMode: Bool = true  // true = Вход, false = Регистрация
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Picker("Опция", selection: $isLoginMode) {
                    Text("Войти").tag(true)
                    Text("Регистрация").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    handleAuthAction()
                }) {
                    Text(isLoginMode ? "Войти" : "Зарегистрироваться")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle(isLoginMode ? "Вход" : "Регистрация")
            .navigationBarItems(trailing: Button("Отмена") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func handleAuthAction() {
        errorMessage = nil
        if isLoginMode {
            // ВХОД через SessionManager
            SessionManager.shared.signIn(email: email, password: password) { result in
                switch result {
                case .success(_):
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    // В случае неудачи восстанавливаем гостевые данные (SessionManager это уже делает)
                }
            }
        } else {
            // РЕГИСТРАЦИЯ - после успешного createUser вызываем сразу SessionManager.signIn
            AuthService.shared.signUp(email: email, password: password) { result in
                switch result {
                case .success(_):
                    // После успешной регистрации сразу залогинимся
                    SessionManager.shared.signIn(email: email, password: password) { signInResult in
                        switch signInResult {
                        case .success(_):
                            presentationMode.wrappedValue.dismiss()
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
