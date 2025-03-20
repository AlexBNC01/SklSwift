//файл TransactionDetailView
import SwiftUI
import CoreData

struct TransactionDetailView: View {
    var transaction: InventoryTransaction

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Карточка с информацией об операции
                transactionInfoCard
                
                // Карточка с информацией о товаре
                if let product = transaction.product {
                    productInfoCard(product: product)
                } else {
                    Text("Нет данных о товаре")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Детали операции")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var transactionInfoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Тип операции:")
                    .bold()
                Spacer()
                Text(transaction.type ?? "")
                    .foregroundColor(transaction.type == "Приход" ? .green : .red)
            }
            if let date = transaction.date {
                HStack {
                    Text("Дата:")
                        .bold()
                    Spacer()
                    Text("\(date, formatter: itemFormatter)")
                        .foregroundColor(.secondary)
                }
            }
            if transaction.type == "Расход" {
                HStack {
                    Text("Списано:")
                        .bold()
                    Spacer()
                    Text("\(transaction.expenseQuantity)")
                        .foregroundColor(.secondary)
                }
                if let purpose = transaction.expensePurpose, !purpose.isEmpty {
                    HStack {
                        Text("Причина:")
                            .bold()
                        Spacer()
                        Text(purpose)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func productInfoCard(product: ProductItem) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Информация о товаре")
                .font(.headline)
                .padding(.bottom, 5)
            
            if let photoData = product.photo,
               let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                detailRow(title: "Название", value: product.name)
                detailRow(title: "Организация", value: product.organization)
                detailRow(title: "Цена", value: String(format: "%.2f", product.price))
                detailRow(title: "Остаток", value: "\(product.quantity)")
                detailRow(title: "Категория", value: product.category)
                detailRow(title: "Для кого", value: product.target)
                detailRow(title: "Штрих-код", value: product.barcode)
            }
            
            if let custom = product.customFields as? [String: String], !custom.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Дополнительные поля:")
                        .bold()
                    ForEach(custom.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        detailRow(title: key, value: value)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func detailRow(title: String, value: String?) -> some View {
        HStack {
            Text("\(title):")
                .bold()
            Spacer()
            Text(value ?? "Не указано")
                .foregroundColor(.secondary)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        
        let transaction = InventoryTransaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.type = "Расход"
        transaction.expenseQuantity = 5
        transaction.expensePurpose = "Испорчено"
        
        let product = ProductItem(context: context)
        product.id = UUID()
        product.name = "Пример товара"
        product.organization = "Организация"
        product.price = 150.0
        product.quantity = 20
        product.category = "Электроника"
        product.target = "Клиент"
        product.barcode = "9876543210"
        product.customFields = ["Цвет": "Синий", "Модель": "X100"] as NSDictionary
        
        transaction.product = product
        
        return NavigationView {
            TransactionDetailView(transaction: transaction)
        }
        .environment(\.managedObjectContext, context)
    }
}
