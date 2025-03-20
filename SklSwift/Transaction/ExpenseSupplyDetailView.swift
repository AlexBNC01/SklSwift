//
// файл  ExpenseSupplyDetailView.swift
//  SklSwift
//
import SwiftUI
import CoreData

struct ExpenseSupplyDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    var product: ProductItem
    var onConfirm: (ProductItem, Int64, String) -> Void
    
    @State private var quantityToExpense: String = ""
    @State private var expensePurpose: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о поставке")) {
                    Text("Название: \(product.name ?? "Нет названия")")
                    Text("Доступно: \(product.quantity)")
                }
                
                Section(header: Text("Детали списания")) {
                    TextField("Количество для списания", text: $quantityToExpense)
                        .keyboardType(.numberPad)
                    TextField("Назначение расхода", text: $expensePurpose)
                }
                
                Button(action: {
                    guard let qty = Int64(quantityToExpense), qty > 0 else {
                        print("Неверное количество")
                        return
                    }
                    onConfirm(product, qty, expensePurpose)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Подтвердить списание")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Списание поставки")
            .navigationBarItems(trailing: Button("Отмена") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ExpenseSupplyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let product = ProductItem(context: context)
        product.id = UUID()
        product.name = "Тестовый товар"
        product.quantity = 50
        return ExpenseSupplyDetailView(product: product) { prod, qty, purpose in
            print("Списано \(qty) шт. с назначением: \(purpose)")
        }
        .environment(\.managedObjectContext, context)
    }
}

