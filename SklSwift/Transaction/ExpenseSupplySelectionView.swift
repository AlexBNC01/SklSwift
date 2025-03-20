//
//  файл ExpenseSupplySelectionView.swift
//  SklSwift
//
import SwiftUI
import CoreData

struct ExpenseSupplySelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // Получаем все товары, у которых доступно списание (количество > 0)
    @FetchRequest(
        entity: ProductItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ProductItem.name, ascending: true)],
        predicate: NSPredicate(format: "quantity > 0")
    ) var availableProducts: FetchedResults<ProductItem>
    
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "Все"
    
    var onSelect: (ProductItem) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Поиск товара")
                    .padding(.horizontal)
                
                // Получаем список категорий из доступных товаров
                let categories = Array(Set(availableProducts.compactMap { $0.category })).sorted()
                if !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button(action: { selectedCategory = "Все" }) {
                                Text("Все")
                                    .padding(8)
                                    .background(selectedCategory == "Все" ? Color.blue : Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    selectedCategory = cat
                                }) {
                                    Text(cat)
                                        .padding(8)
                                        .background(selectedCategory == cat ? Color.blue : Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                List {
                    ForEach(filteredProducts, id: \.id) { product in
                        Button(action: {
                            onSelect(product)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.name ?? "Нет названия")
                                    Text("Доступно: \(product.quantity)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выбрать поставку")
            .navigationBarItems(trailing: Button("Отмена") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Фильтрация товаров по поиску и выбранной категории
    var filteredProducts: [ProductItem] {
        availableProducts.filter { product in
            let matchesSearch = searchText.isEmpty || (product.name?.lowercased().contains(searchText.lowercased()) ?? false)
            let matchesCategory = (selectedCategory == "Все") || (product.category == selectedCategory)
            return matchesSearch && matchesCategory
        }
    }
}

struct ExpenseSupplySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        ExpenseSupplySelectionView { _ in }
            .environment(\.managedObjectContext, context)
    }
}
