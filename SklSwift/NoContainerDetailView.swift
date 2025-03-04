//NoContainerDetailView
import SwiftUI
import CoreData

struct NoContainerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Выбираем только товары без контейнера, у которых quantity > 0
    @FetchRequest(
        entity: ProductItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ProductItem.name, ascending: true)],
        predicate: NSPredicate(format: "container == nil AND quantity > 0")
    ) var products: FetchedResults<ProductItem>

    var body: some View {
        List {
            ForEach(products, id: \.id) { product in
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
                }
            }
            .onDelete(perform: deleteProducts)
        }
        .navigationTitle("Без контейнера")
    }
    
    private func deleteProducts(at offsets: IndexSet) {
        for index in offsets {
            let product = products[index]
            viewContext.delete(product)
        }
        do {
            try viewContext.save()
        } catch {
            print("Ошибка удаления товара: \(error)")
        }
    }
}

struct NoContainerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NoContainerDetailView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
