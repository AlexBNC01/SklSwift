//файл ProductDetailView
import SwiftUI
import CoreData

struct ProductDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var product: ProductItem

    // Редактируемые поля
    @State private var productName: String
    @State private var price: String
    @State private var quantity: String
    @State private var category: String
    @State private var target: String
    @State private var organization: String
    @State private var barcode: String
    
    // Режим редактирования
    @State private var isEditing: Bool = false
    
    // Форматтер для даты в формате ДД.ММ.ГГГГ
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }
    
    // Вычисляемая свойство: определяем дату создания товара через самую раннюю транзакцию
    var creationDate: Date? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<InventoryTransaction> = InventoryTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "product == %@", product)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InventoryTransaction.date, ascending: true)]
        request.fetchLimit = 1
        do {
            let transactions = try context.fetch(request)
            return transactions.first?.date
        } catch {
            print("Ошибка выборки транзакций: \(error)")
            return nil
        }
    }
    
    init(product: ProductItem) {
        _product = State(initialValue: product)
        _productName = State(initialValue: product.name ?? "")
        _price = State(initialValue: String(format: "%.2f", product.price))
        _quantity = State(initialValue: String(product.quantity))
        _category = State(initialValue: product.category ?? "")
        _target = State(initialValue: product.target ?? "")
        _organization = State(initialValue: product.organization ?? "")
        _barcode = State(initialValue: product.barcode ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Изображение товара (если имеется)
                if let photoData = product.photo, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                
                // Карточка с информацией о товаре
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        TextField("Название товара", text: $productName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding([.top, .horizontal])
                    } else {
                        Text(productName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding([.top, .horizontal])
                    }
                    
                    Divider()
                    
                    // Новая секция с датой добавления
                    if let date = creationDate {
                        HStack {
                            Text("Дата добавления:")
                                .bold()
                            Spacer()
                            Text(dateFormatter.string(from: date))
                        }
                        .padding(.horizontal)
                    }
                    
                    infoRow(title: "Организация", value: isEditing ? $organization : .constant(organization))
                    infoRow(title: "Цена", value: isEditing ? $price : .constant(price))
                    infoRow(title: "Количество", value: isEditing ? $quantity : .constant(quantity))
                    infoRow(title: "Категория", value: isEditing ? $category : .constant(category))
                    infoRow(title: "Для кого", value: isEditing ? $target : .constant(target))
                    infoRow(title: "Штрих-код", value: isEditing ? $barcode : .constant(barcode))
                    
                    // Дополнительные поля (только для чтения)
                    if let custom = product.customFields as? [String: String], !custom.isEmpty {
                        ForEach(custom.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text("\(key):")
                                    .bold()
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(value)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
                
                // Кнопка сохранения в режиме редактирования
                if isEditing {
                    Button("Сохранить изменения") {
                        saveChanges()
                        isEditing = false
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding([.top, .horizontal])
                }
                
                // Кнопка переключения режима редактирования
                Button(isEditing ? "Отмена" : "Редактировать") {
                    isEditing.toggle()
                    if !isEditing {
                        // Отмена редактирования – восстановление исходных данных
                        productName = product.name ?? ""
                        price = String(format: "%.2f", product.price)
                        quantity = String(product.quantity)
                        category = product.category ?? ""
                        target = product.target ?? ""
                        organization = product.organization ?? ""
                        barcode = product.barcode ?? ""
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Детали товара")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func infoRow(title: String, value: Binding<String>) -> some View {
        HStack {
            Text("\(title):")
                .bold()
                .foregroundColor(.secondary)
            Spacer()
            if isEditing {
                TextField(title, text: value)
                    .padding(5)
                    .background(Color.white)
                    .cornerRadius(8)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(value.wrappedValue)
            }
        }
        .padding(.horizontal)
    }
    
    private func saveChanges() {
        product.name = productName
        product.price = Double(price) ?? 0.0
        product.quantity = Int64(quantity) ?? 0
        product.category = category
        product.target = target
        product.organization = organization
        product.barcode = barcode

        do {
            try viewContext.save()
        } catch {
            print("Ошибка при сохранении изменений: \(error)")
        }
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let product = ProductItem(context: context)
        product.id = UUID()
        product.name = "Пример товара"
        product.organization = "Пример организации"
        product.price = 99.99
        product.quantity = 5
        product.category = "Пример категории"
        product.target = "Пример для кого"
        product.barcode = "1234567890"
        product.customFields = ["Цвет": "Красный", "Размер": "M"] as NSDictionary
        
        return NavigationView {
            ProductDetailView(product: product)
        }
        .environment(\.managedObjectContext, context)
    }
}
