//
//  файл FirestoreCheckView.swift
//  SklSwift
//
import SwiftUI
import Firebase
import FirebaseFirestore

struct FirestoreCheckView: View {
    @State private var statusMessage: String = ""
    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            Text("Проверка Firestore")
                .font(.largeTitle)
                .padding(.top, 40)

            // Кнопка для сохранения тестового документа
            Button("Сохранить тестовый документ") {
                saveTestDocument()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            // Кнопка для загрузки тестового документа
            Button("Загрузить тестовый документ") {
                loadTestDocument()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

            // Статус-сообщение для отображения результата
            Text(statusMessage)
                .foregroundColor(.blue)
                .padding(.horizontal)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // Запись тестовых данных в Firestore
    private func saveTestDocument() {
        // Примерные данные
        let testData: [String: Any] = [
            "timestamp": Timestamp(date: Date()),
            "message": "Привет, Firestore!"
        ]

        // Сохраняем в коллекцию "test", документ "testDoc"
        db.collection("test").document("testDoc").setData(testData) { error in
            if let error = error {
                statusMessage = "Ошибка при сохранении: \(error.localizedDescription)"
            } else {
                statusMessage = "Документ успешно сохранён!"
            }
        }
    }

    // Загрузка тестовых данных из Firestore
    private func loadTestDocument() {
        db.collection("test").document("testDoc").getDocument { snapshot, error in
            if let error = error {
                statusMessage = "Ошибка при загрузке: \(error.localizedDescription)"
            } else if let data = snapshot?.data() {
                statusMessage = "Документ загружен: \(data)"
            } else {
                statusMessage = "Документ не найден!"
            }
        }
    }
}

struct FirestoreCheckView_Previews: PreviewProvider {
    static var previews: some View {
        FirestoreCheckView()
    }
}

