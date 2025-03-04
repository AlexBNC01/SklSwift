//ExpenseProductDetailView
import SwiftUI
import CoreData

struct ExpenseProductDetailView: View {
    var product: ProductItem
    var expenseQuantity: Int64
    var onConfirm: (ProductItem, Int64) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var quantityToDeduct: Int64 = 0
    @State private var selectedPrice: Double = 0.0
    @State private var targetForExpense: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Отображаем изображение, если есть
                if let photoData = product.photo, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(product.name ?? "Не указано")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    infoRow(title: "Организация", value: product.organization ?? "Не указано")
                    infoRow(title: "Цена", value: String(format: "%.2f", product.price))
                    infoRow(title: "Доступно", value: "\(product.quantity)")
                    infoRow(title: "Категория", value: product.category ?? "Не указано")
                    infoRow(title: "Для кого", value: product.target ?? "Не указано")
                    infoRow(title: "Штрих-код", value: product.barcode ?? "Не указано")
                    
                    // Ввод данных для расхода
                    TextField("Количество для списания", value: $quantityToDeduct, format: .number)
                        .padding()
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Цена для списания", value: $selectedPrice, format: .number)
                        .padding()
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Назначение расхода", text: $targetForExpense)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        // Подтверждение списания
                        onConfirm(product, quantityToDeduct)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Подтвердить списание")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Детали поставки")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text("\(title):")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

struct ExpenseProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let product = ProductItem(context: context)
        product.id = UUID()
        product.name = "Пример поставки"
        product.organization = "Пример организации"
        product.price = 50.0
        product.quantity = 15
        product.category = "Пример категории"
        product.target = "Пример для кого"
        product.barcode = "9876543210"
        product.customFields = ["Цвет": "Синий", "Размер": "L"] as NSDictionary
        
        return NavigationView {
            ExpenseProductDetailView(product: product, expenseQuantity: 5) { chosen, quantity in
                print("Подтвержден расход для \(chosen.name ?? "") на \(quantity) шт.")
            }
        }
        .environment(\.managedObjectContext, context)
    }
}
