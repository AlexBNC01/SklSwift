// файл WriteOffProductView
import SwiftUI
import CoreData

struct WriteOffProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var product: ProductItem
    var onCompletion: (() -> Void)? = nil

    @State private var quantityToWriteOff: Int64 = 0
    @State private var writeOffPurpose: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Информация о товаре")) {
                Text(product.name ?? "Нет названия")
                Text("Доступно: \(product.quantity)")
            }
            
            Section(header: Text("Детали списания")) {
                TextField("Количество для списания", value: $quantityToWriteOff, format: .number)
                    .keyboardType(.numberPad)
                TextField("Назначение списания", text: $writeOffPurpose)
            }
            
            Button(action: {
                writeOffProduct()
            }) {
                Text("Подтвердить списание")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("Списание товара")
    }
    
    private func writeOffProduct() {
        guard quantityToWriteOff > 0 else { return }
        guard product.quantity >= quantityToWriteOff else {
            // Можно добавить предупреждение о том, что списывается больше, чем доступно
            return
        }
        
        // Уменьшаем количество товара
        product.quantity -= quantityToWriteOff
        
        // Создаем транзакцию списания
        let transaction = InventoryTransaction(context: viewContext)
        transaction.id = UUID()
        transaction.date = Date()  // Устанавливаем текущую дату
        transaction.type = "Списание"
        transaction.product = product
        // Записываем дополнительные параметры
        transaction.expenseQuantity = quantityToWriteOff
        transaction.expensePurpose = writeOffPurpose
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
            onCompletion?()
        } catch {
            print("Ошибка сохранения транзакции: \(error)")
        }
    }
}

struct WriteOffProductView_Previews: PreviewProvider {
    static var previews: some View {
        // Для превью создаем тестовый объект
        let context = PersistenceController.shared.container.viewContext
        let product = ProductItem(context: context)
        product.id = UUID()
        product.name = "Пример товара"
        product.quantity = 20
        return NavigationView {
            WriteOffProductView(product: product)
        }
        .environment(\.managedObjectContext, context)
    }
}
