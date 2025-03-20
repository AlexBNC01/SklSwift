//файл ProductFieldsSettingsView
import SwiftUI

struct ProductFieldsSettingsView: View {
    @State private var customFieldName: String = ""
    @State private var customFields: [String] = UserDefaults.standard.stringArray(forKey: "CustomFields") ?? ["название", "организация", "цена"]

    var body: some View {
        Form {
            Section(header: Text("Поля для товара")) {
                List {
                    ForEach(customFields, id: \.self) { field in
                        Text(field)
                    }
                    .onDelete(perform: deleteField)
                }
                HStack {
                    TextField("Новое поле", text: $customFieldName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Добавить") {
                        addField()
                    }
                    .disabled(customFieldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle("Поля для товара")
        .onDisappear {
            UserDefaults.standard.set(customFields, forKey: "CustomFields")
        }
    }
    
    private func addField() {
        let trimmed = customFieldName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        customFields.append(trimmed)
        customFieldName = ""
    }
    
    private func deleteField(at offsets: IndexSet) {
        customFields.remove(atOffsets: offsets)
    }
}

struct ProductFieldsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProductFieldsSettingsView()
        }
    }
}
