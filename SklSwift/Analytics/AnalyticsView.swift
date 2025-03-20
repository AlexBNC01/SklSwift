// файл AnalyticsView
import SwiftUI
import CoreData
import UniformTypeIdentifiers

// Структура для хранения аналитических данных
struct AnalyticsData {
    var totalPurchaseCost: Double = 0    // Сумма денег на закупку товаров (Приход)
    var totalExpenseCost: Double = 0       // Сумма денег на списания (Расход)
    var purchaseByCategory: [String: Double] = [:]
    var expenseByCategory: [String: Double] = [:]
    var purchaseByTechnique: [String: Double] = [:]
    var expenseByTechnique: [String: Double] = [:]
    var incomingCount: Int = 0             // Количество операций "Приход"
    var expenseCount: Int = 0              // Количество операций "Расход"
}

struct AnalyticsView: View {
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var analyticsData = AnalyticsData()
    @State private var showAnalytics: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var exportFileURL: URL? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Выберите период")) {
                        DatePicker("Начало", selection: $startDate, displayedComponents: .date)
                        DatePicker("Конец", selection: $endDate, displayedComponents: .date)
                        Button("Обновить статистику") {
                            analyticsData = computeAnalytics()
                            showAnalytics = true
                        }
                    }
                    
                    if showAnalytics {
                        Section(header: Text("Общая статистика")) {
                            HStack {
                                Text("Закупка товаров:")
                                Spacer()
                                Text(String(format: "%.2f ₽", analyticsData.totalPurchaseCost))
                            }
                            HStack {
                                Text("Расходы:")
                                Spacer()
                                Text(String(format: "%.2f ₽", analyticsData.totalExpenseCost))
                            }
                            HStack {
                                Text("Операций закупки:")
                                Spacer()
                                Text("\(analyticsData.incomingCount)")
                            }
                            HStack {
                                Text("Операций расходов:")
                                Spacer()
                                Text("\(analyticsData.expenseCount)")
                            }
                        }
                        
                        Section(header: Text("По категориям (Закупка / Расход)")) {
                            ForEach(Array(analyticsData.purchaseByCategory.keys).sorted(), id: \.self) { key in
                                HStack {
                                    Text(key)
                                    Spacer()
                                    Text(String(format: "%.2f ₽", analyticsData.purchaseByCategory[key] ?? 0))
                                    Text("/")
                                    Text(String(format: "%.2f ₽", analyticsData.expenseByCategory[key] ?? 0))
                                }
                            }
                        }
                        
                        Section(header: Text("По технике (Закупка / Расход)")) {
                            ForEach(Array(analyticsData.purchaseByTechnique.keys).sorted(), id: \.self) { key in
                                HStack {
                                    Text(key)
                                    Spacer()
                                    Text(String(format: "%.2f ₽", analyticsData.purchaseByTechnique[key] ?? 0))
                                    Text("/")
                                    Text(String(format: "%.2f ₽", analyticsData.expenseByTechnique[key] ?? 0))
                                }
                            }
                        }
                    }
                }
                
                Button("Экспортировать таблицу") {
                    exportAnalytics()
                }
                .padding()
            }
            .navigationTitle("Аналитика")
            .sheet(isPresented: $showExportSheet, onDismiss: {
                if let url = exportFileURL {
                    try? FileManager.default.removeItem(at: url)
                    exportFileURL = nil
                }
            }) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // Вычисление аналитики по выбранному периоду
    private func computeAnalytics() -> AnalyticsData {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<InventoryTransaction> = InventoryTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        var data = AnalyticsData()
        
        do {
            let transactions = try context.fetch(request)
            
            for t in transactions where t.type == "Расход" {
                if let product = t.product {
                    data.expenseCount += 1
                    let expenseCost = product.price * Double(t.expenseQuantity)
                    data.totalExpenseCost += expenseCost
                    
                    let cat = product.category ?? "Без категории"
                    data.expenseByCategory[cat, default: 0] += expenseCost
                    
                    let tech = product.target ?? "Без техники"
                    data.expenseByTechnique[tech, default: 0] += expenseCost
                }
            }
            
            var expenseSumByProduct: [NSManagedObjectID: Int64] = [:]
            for t in transactions where t.type == "Расход" {
                if let product = t.product {
                    expenseSumByProduct[product.objectID, default: 0] += t.expenseQuantity
                }
            }
            
            for t in transactions where t.type == "Приход" {
                if let product = t.product {
                    data.incomingCount += 1
                    let expenseSum = expenseSumByProduct[product.objectID] ?? 0
                    let purchasedQuantity = product.quantity + expenseSum
                    let purchaseCost = product.price * Double(purchasedQuantity)
                    data.totalPurchaseCost += purchaseCost
                    
                    let cat = product.category ?? "Без категории"
                    data.purchaseByCategory[cat, default: 0] += purchaseCost
                    
                    let tech = product.target ?? "Без техники"
                    data.purchaseByTechnique[tech, default: 0] += purchaseCost
                }
            }
        } catch {
            print("Ошибка выборки транзакций: \(error)")
        }
        
        return data
    }
    
    // Экспорт аналитики в CSV-файл
    private func exportAnalytics() {
        let data = computeAnalytics()
        var csv = "Параметр,Значение\n"
        csv += "Закупка товаров,\"\(data.totalPurchaseCost)\"\n"
        csv += "Расходы,\"\(data.totalExpenseCost)\"\n"
        csv += "Операций закупки,\"\(data.incomingCount)\"\n"
        csv += "Операций расходов,\"\(data.expenseCount)\"\n\n"
        
        csv += "Категория,Закупка,Расход\n"
        for key in Array(data.purchaseByCategory.keys).sorted() {
            let purchase = data.purchaseByCategory[key] ?? 0
            let expense = data.expenseByCategory[key] ?? 0
            csv += "\"\(key)\",\"\(purchase)\",\"\(expense)\"\n"
        }
        
        csv += "\nТехника,Закупка,Расход\n"
        for key in Array(data.purchaseByTechnique.keys).sorted() {
            let purchase = data.purchaseByTechnique[key] ?? 0
            let expense = data.expenseByTechnique[key] ?? 0
            csv += "\"\(key)\",\"\(purchase)\",\"\(expense)\"\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Analytics_\(Date().timeIntervalSince1970).csv"
        let url = tempDir.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportFileURL = url
            showExportSheet = true
        } catch {
            print("Ошибка экспорта аналитики: \(error)")
        }
    }
}

// Единственная реализация ShareSheet
struct ShareSheet2: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
         UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
