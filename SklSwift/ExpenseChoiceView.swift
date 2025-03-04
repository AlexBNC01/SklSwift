//ExpenseChoiceView
import SwiftUI
import CoreData

struct ExpenseChoiceView: View {
    var candidates: [ProductItem]
    var expenseQuantity: Int64
    var onSelect: (ProductItem) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(candidates, id: \.id) { product in
                NavigationLink(destination: ExpenseProductDetailView(product: product, expenseQuantity: expenseQuantity, onConfirm: { chosen, quantity in
                    onSelect(chosen)
                    presentationMode.wrappedValue.dismiss()
                })) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name ?? "Нет названия")
                                .font(.headline)
                            Text("Доступно: \(product.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Выберите поставку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ExpenseChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let product1 = ProductItem(context: context)
        product1.id = UUID()
        product1.name = "Поставка 1"
        product1.quantity = 10
        
        let product2 = ProductItem(context: context)
        product2.id = UUID()
        product2.name = "Поставка 2"
        product2.quantity = 20
        
        return ExpenseChoiceView(candidates: [product1, product2], expenseQuantity: 5) { chosen in
            print("Выбрано: \(chosen.name ?? "")")
        }
        .environment(\.managedObjectContext, context)
    }
}
