import SwiftUI
import CoreData

struct ContainerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var container: WarehouseContainer

    @FetchRequest var products: FetchedResults<ProductItem>
    @State private var searchText: String = ""
    
    init(container: WarehouseContainer) {
        self.container = container
        // Отображаем только товары с quantity > 0
        _products = FetchRequest(
            entity: ProductItem.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \ProductItem.name, ascending: true)],
            predicate: NSPredicate(format: "container == %@ AND quantity > 0", container)
        )
    }
    
    // Фильтрация товаров по введённому тексту
    var filteredProducts: [ProductItem] {
        if searchText.isEmpty {
            return Array(products)
        } else {
            return products.filter { product in
                if let name = product.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return false
            }
        }
    }
    
    var body: some View {
        VStack {
            // Поле поиска для товаров внутри контейнера
            SearchBar(text: $searchText, placeholder: "Поиск товара")
                .padding(.horizontal)
                .padding(.top, 8)
            
            List {
                ForEach(filteredProducts, id: \.id) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.name ?? "Нет названия")
                                    .font(.headline)
                                Text("Категория: \(product.category ?? "")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("Кол-во: \(product.quantity)")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteProducts)
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle(container.name ?? "Контейнер")
    }
    
    private func deleteProducts(at offsets: IndexSet) {
        for index in offsets {
            let product = filteredProducts[index]
            viewContext.delete(product)
        }
        do {
            try viewContext.save()
        } catch {
            print("Ошибка удаления товара: \(error)")
        }
    }
}

struct ContainerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let container = WarehouseContainer(context: context)
        container.id = UUID()
        container.name = "Тестовый контейнер"
        return NavigationView {
            ContainerDetailView(container: container)
        }
        .environment(\.managedObjectContext, context)
    }
}
