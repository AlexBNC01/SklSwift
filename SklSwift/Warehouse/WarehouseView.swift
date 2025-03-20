// файл WarehouseView
import SwiftUI
import CoreData

struct WarehouseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText: String = ""
    
    // Переменные для редактирования названия контейнера
    @State private var editingContainer: WarehouseContainer? = nil
    @State private var newContainerName: String = ""
    @State private var showEditContainerSheet: Bool = false

    @FetchRequest(
        entity: WarehouseContainer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WarehouseContainer.name, ascending: true)]
    ) var containers: FetchedResults<WarehouseContainer>
    
    var body: some View {
        NavigationView {
            VStack {
                // Универсальный поиск: по названию контейнера или по товарам внутри
                SearchBar(text: $searchText, placeholder: "Поиск контейнера или товара")
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                List {
                    // Фильтруем контейнеры: показываем те, у которых имя или хотя бы один товар соответствует запросу
                    ForEach(containers.filter { container in
                        if searchText.isEmpty { return true }
                        let lowerQuery = searchText.lowercased()
                        let containerNameMatches = container.name?.lowercased().contains(lowerQuery) ?? false
                        let productMatches = (container.products as? Set<ProductItem>)?.filter {
                            ($0.name?.lowercased().contains(lowerQuery)) ?? false
                        } ?? []
                        return containerNameMatches || !productMatches.isEmpty
                    }, id: \.id) { container in
                        NavigationLink(destination: ContainerDetailView(container: container)) {
                            HStack {
                                Text(container.name ?? "Без названия")
                                    .font(.headline)
                                Spacer()
                                Text("Всего: \(totalQuantity(for: container))")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                        .contextMenu {
                            Button("Редактировать") {
                                editingContainer = container
                                newContainerName = container.name ?? ""
                                showEditContainerSheet = true
                            }
                            Button(role: .destructive) {
                                deleteContainer(container)
                            } label: {
                                Text("Удалить")
                            }
                        }
                    }
                    
                    // Если поиск пустой – показываем контейнер "Без контейнера"
                    if searchText.isEmpty {
                        NavigationLink(destination: NoContainerDetailView()) {
                            HStack {
                                Text("Без контейнера")
                                    .font(.headline)
                                Spacer()
                                Text("Всего: \(totalQuantityForNoContainer())")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        // При поиске проверяем, есть ли товары без контейнера, удовлетворяющие запросу
                        let noContainerMatches = noContainerProducts().filter {
                            ($0.name?.lowercased().contains(searchText.lowercased())) ?? false
                        }
                        if !noContainerMatches.isEmpty {
                            NavigationLink(destination: NoContainerDetailView()) {
                                HStack {
                                    Text("Без контейнера")
                                        .font(.headline)
                                    Spacer()
                                    Text("Найдено: \(noContainerMatches.count) товар(ов)")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Склад")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addDummyContainer) {
                        Image(systemName: "plus")
                    }
                }
            }
            // Sheet для редактирования названия контейнера
            .sheet(isPresented: $showEditContainerSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Новое название контейнера")) {
                            TextField("Название", text: $newContainerName)
                        }
                    }
                    .navigationTitle("Редактирование")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Сохранить") {
                                if let container = editingContainer {
                                    container.name = newContainerName
                                    do {
                                        try viewContext.save()
                                    } catch {
                                        print("Ошибка сохранения: \(error)")
                                    }
                                }
                                showEditContainerSheet = false
                                editingContainer = nil
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") {
                                showEditContainerSheet = false
                                editingContainer = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Подсчитываем общий остаток товаров в контейнере (только товары с quantity > 0)
    private func totalQuantity(for container: WarehouseContainer) -> Int64 {
        let request: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
        request.predicate = NSPredicate(format: "container == %@ AND quantity > 0", container)
        do {
            let products = try viewContext.fetch(request)
            return products.reduce(0) { $0 + $1.quantity }
        } catch {
            print("Ошибка подсчёта: \(error)")
            return 0
        }
    }
    
    private func totalQuantityForNoContainer() -> Int64 {
        let request: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
        request.predicate = NSPredicate(format: "container == nil AND quantity > 0")
        do {
            let products = try viewContext.fetch(request)
            return products.reduce(0) { $0 + $1.quantity }
        } catch {
            print("Ошибка подсчёта: \(error)")
            return 0
        }
    }
    
    // Товары без контейнера (запрос без ограничения по количеству – для поиска)
    private func noContainerProducts() -> [ProductItem] {
        let request: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
        request.predicate = NSPredicate(format: "container == nil")
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Ошибка выборки: \(error)")
            return []
        }
    }
    
    // Функция добавления тестового контейнера с тестовым товаром
    private func addDummyContainer() {
        let newContainer = WarehouseContainer(context: viewContext)
        newContainer.id = UUID()
        newContainer.name = "Контейнер \(containers.count + 1)"
        
        // Создаём тестовый товар с количеством > 0
        let newProduct = ProductItem(context: viewContext)
        newProduct.id = UUID()
        newProduct.name = "Товар \(Int.random(in: 1...100))"
        newProduct.category = "Категория \(Int.random(in: 1...5))"
        newProduct.price = Double.random(in: 10...100)
        newProduct.organization = "Организация"
        newProduct.target = "Клиент"
        newProduct.barcode = "1234567890"
        newProduct.quantity = Int64.random(in: 1...10)
        newProduct.container = newContainer
        
        do {
            try viewContext.save()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }
    
    // Функция удаления контейнера
    private func deleteContainer(_ container: WarehouseContainer) {
        viewContext.delete(container)
        do {
            try viewContext.save()
        } catch {
            print("Ошибка удаления контейнера: \(error)")
        }
    }
}

struct WarehouseView_Previews: PreviewProvider {
    static var previews: some View {
        WarehouseView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
