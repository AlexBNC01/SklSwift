// файл ExportHistoryView
import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ExportHistoryView: View {
    @State private var selectedType: String = "Все" // варианты: "Все", "Приход", "Расход"
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var categoryFilter: String = ""
    @State private var fileURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let operationTypes = ["Все", "Приход", "Расход"]
    
    var body: some View {
        Form {
            Section(header: Text("Фильтры экспорта")) {
                Picker("Тип операции", selection: $selectedType) {
                    ForEach(operationTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                DatePicker("Начало периода", selection: $startDate, displayedComponents: .date)
                DatePicker("Конец периода", selection: $endDate, displayedComponents: .date)
                
                TextField("Категория (если нужно)", text: $categoryFilter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section {
                Button("Экспортировать историю") {
                    exportHistory()
                }
            }
        }
        .navigationTitle("Экспорт истории")
        .sheet(isPresented: $showShareSheet, onDismiss: {
            if let url = fileURL {
                try? FileManager.default.removeItem(at: url)
                fileURL = nil
            }
        }) {
            if let url = fileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка экспорта"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func exportHistory() {
        let transactions = fetchFilteredTransactions()
        
        // Собираем объединённый набор ключей для дополнительных полей
        var additionalKeys = Set<String>()
        for t in transactions {
            if let custom = t.product?.customFields as? [String: String] {
                additionalKeys.formUnion(custom.keys)
            }
        }
        let sortedAdditionalKeys = additionalKeys.sorted()
        
        // Формируем заголовок CSV: удаляем столбцы ID и Штрихкод, добавляем "Количество"
        var csvHeader = "Дата,Тип,Название,Организация,Цена,Количество,Категория,Для кого"
        for key in sortedAdditionalKeys {
            csvHeader += ",\"\(key)\""
        }
        csvHeader += "\n"
        
        // Формируем строки для каждой транзакции
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        var csvBody = ""
        for t in transactions {
            let date = t.date != nil ? formatter.string(from: t.date!) : ""
            let type = t.type ?? ""
            let product = t.product
            let name = product?.name ?? ""
            let org = product?.organization ?? ""
            let price = "\(product?.price ?? 0)"
            let quantity = "\(product?.quantity ?? 0)"
            let category = product?.category ?? ""
            let target = product?.target ?? ""
            
            var row = "\"\(date)\",\"\(type)\",\"\(name)\",\"\(org)\",\"\(price)\",\"\(quantity)\",\"\(category)\",\"\(target)\""
            
            // Для каждого дополнительного поля
            let customDict = product?.customFields as? [String: String] ?? [:]
            for key in sortedAdditionalKeys {
                let value = customDict[key] ?? ""
                row += ",\"\(value)\""
            }
            row += "\n"
            csvBody += row
        }
        
        let csv = csvHeader + csvBody
        
        // Сохраняем CSV во временный файл
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "ExportedHistory_\(Date().timeIntervalSince1970).csv"
        let url = tempDir.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            showShareSheet = true
        } catch {
            alertMessage = "Не удалось сохранить файл: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func fetchFilteredTransactions() -> [InventoryTransaction] {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<InventoryTransaction> = InventoryTransaction.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Фильтр по дате
        let datePredicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        predicates.append(datePredicate)
        
        // Фильтр по типу операции (если выбран не "Все")
        if selectedType != "Все" {
            let typePredicate = NSPredicate(format: "type == %@", selectedType)
            predicates.append(typePredicate)
        }
        
        // Фильтр по категории (если указано)
        if !categoryFilter.trimmingCharacters(in: .whitespaces).isEmpty {
            let categoryPredicate = NSPredicate(format: "product.category CONTAINS[cd] %@", categoryFilter)
            predicates.append(categoryPredicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Ошибка выборки транзакций: \(error)")
            return []
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
         UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

struct ExportHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExportHistoryView()
        }
    }
}
