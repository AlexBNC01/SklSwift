//
//  CategoryOptionsSettingsView.swift
//  SklSwift
//
import SwiftUI

struct CategoryOptionsSettingsView: View {
    @State private var newOption: String = ""
    @State private var options: [String] = UserDefaults.standard.stringArray(forKey: "CategoryOptions") ?? ["Электроника", "Продукты", "Одежда"]
    
    var body: some View {
        Form {
            Section(header: Text("Опции для поля 'Категория'")) {
                List {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                    }
                    .onDelete(perform: deleteOption)
                }
                HStack {
                    TextField("Новая опция", text: $newOption)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Добавить") {
                        addOption()
                    }
                    .disabled(newOption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle("Опции категории")
        .onDisappear {
            UserDefaults.standard.set(options, forKey: "CategoryOptions")
        }
    }
    
    private func addOption() {
        let trimmed = newOption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        options.append(trimmed)
        newOption = ""
    }
    
    private func deleteOption(at offsets: IndexSet) {
        options.remove(atOffsets: offsets)
    }
}

struct CategoryOptionsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoryOptionsSettingsView()
        }
    }
}

