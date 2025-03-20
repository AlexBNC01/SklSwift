import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isAuthenticated: Bool = false
    
    var body: some View {
        // Если пользователь уже авторизован или вход произошёл прямо сейчас,
        // отображаем MainTabView, иначе - экран логина/регистрации.
        if isAuthenticated || Auth.auth().currentUser != nil {
            MainTabView()
        } else {
            VStack(spacing: 16) {
                Text("Авторизация")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 20) {
                    Button("Войти") {
                        AuthService.shared.signIn(email: email, password: password) { result in
                            switch result {
                            case .success:
                                isAuthenticated = true
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    Button("Регистрация") {
                        AuthService.shared.signUp(email: email, password: password) { result in
                            switch result {
                            case .success:
                                isAuthenticated = true
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
