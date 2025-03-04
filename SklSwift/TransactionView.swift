import SwiftUI
import CoreData
import UniformTypeIdentifiers

enum ExpenseEntryMode: String, CaseIterable, Identifiable {
    case quick = "Быстрый расход"
    case choose = "Выбрать поставку"
    
    var id: String { self.rawValue }
}

struct CustomField: Identifiable {
    var id = UUID()
    var name: String
    var value: String
}

struct TransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Основные поля операции
    @State private var transactionType: String = "Приход" // "Приход" или "Расход"
    @State private var productName: String = ""
    @State private var organization: String = ""
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var category: String = ""
    @State private var target: String = ""
    @State private var barcode: String = ""
    @State private var productImage: UIImage? = nil
    
    // Флаги для выбора фото (без Firebase)
    @State private var showingImagePicker: Bool = false
    @State private var showPhotoOptions: Bool = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // Дополнительные поля – загружаются из UserDefaults (если это было до Firebase)
    @State private var customFields: [CustomField] = {
        let saved = UserDefaults.standard.stringArray(forKey: "CustomFields") ?? ["название", "организация", "цена"]
        return saved.map { CustomField(name: $0, value: "") }
    }()
    
    // Опции для выпадающих списков для полей "Категория" и "Техника"
    @State private var categoryOptions: [String] = UserDefaults.standard.stringArray(forKey: "CategoryOptions") ?? ["Электроника", "Продукты", "Одежда"]
    @State private var techniqueOptions: [String] = UserDefaults.standard.stringArray(forKey: "TechniqueOptions") ?? ["Компьютер", "Телефон", "Планшет"]
    
    // Остальные переменные
    @State private var filteredProducts: [ProductItem] = []
    @FetchRequest(
        entity: ProductItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ProductItem.name, ascending: true)]
    ) var allProducts: FetchedResults<ProductItem>
    
    @State private var selectedContainer: WarehouseContainer? = nil
    @FetchRequest(
        entity: WarehouseContainer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WarehouseContainer.name, ascending: true)]
    ) var availableContainers: FetchedResults<WarehouseContainer>
    
    @State private var showingBarcodeScanner: Bool = false
    @State private var expenseEntryMode: ExpenseEntryMode = .quick
    @State private var showExpenseSupplySelection: Bool = false
    @State private var chosenProduct: ProductItem? = nil
    @State private var showExpenseDetailSheet: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Picker("Тип операции", selection: $transactionType) {
                    Text("Приход").tag("Приход")
                    Text("Расход").tag("Расход")
                }
                
                if transactionType == "Расход" {
                    Section(header: Text("Режим расхода")) {
                        Picker("Режим", selection: $expenseEntryMode) {
                            ForEach(ExpenseEntryMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                if transactionType == "Приход" || (transactionType == "Расход" && expenseEntryMode == .quick) {
                    Section(header: Text("Информация о товаре")) {
                        TextField("Название", text: $productName)
                            .onChange(of: productName) { newValue in
                                filteredProducts = allProducts.filter { $0.name?.contains(newValue) == true }
                            }
                        
                        if !filteredProducts.isEmpty {
                            List(filteredProducts, id: \.id) { product in
                                Button(action: {
                                    productName = product.name ?? ""
                                }) {
                                    Text(product.name ?? "Нет названия")
                                }
                            }
                            .frame(height: 150)
                        }
                        
                        TextField("Организация", text: $organization)
                        TextField("Цена", text: $price)
                            .keyboardType(.decimalPad)
                        TextField("Количество", text: $quantity)
                            .keyboardType(.numberPad)
                        
                        // Поле "Категория" с выпадающим списком
                        HStack {
                            TextField("Категория", text: $category)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Menu {
                                ForEach(categoryOptions, id: \.self) { option in
                                    Button(option) {
                                        category = option
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Поле "Техника" (ранее "Для кого") с выпадающим списком
                        HStack {
                            TextField("Техника", text: $target)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Menu {
                                ForEach(techniqueOptions, id: \.self) { option in
                                    Button(option) {
                                        target = option
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        HStack {
                            TextField("Штрих-код", text: $barcode)
                                .disabled(true)
                            Button(action: {
                                showingBarcodeScanner = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                            }
                        }
                        
                        Button(action: {
                            showPhotoOptions = true
                        }) {
                            HStack {
                                Text("Добавить фото")
                                Spacer()
                                if let image = productImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .actionSheet(isPresented: $showPhotoOptions) {
                            ActionSheet(title: Text("Выберите источник"), message: nil, buttons: actionSheetButtons())
                        }
                    }
                    
                    Section(header: Text("Выбор контейнера")) {
                        Picker("Контейнер", selection: $selectedContainer) {
                            Text("Без контейнера").tag(WarehouseContainer?.none)
                            ForEach(availableContainers, id: \.id) { container in
                                Text(container.name ?? "Без названия")
                                    .tag(Optional(container))
                            }
                        }
                    }
                    
                    Section(header: Text("Дополнительные поля")) {
                        ForEach($customFields) { $field in
                            TextField(field.name, text: $field.value)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Button("Сохранить операцию") {
                        saveTransactionQuickExpense()
                    }
                } else if transactionType == "Расход" && expenseEntryMode == .choose {
                    Section {
                        Button(action: {
                            showExpenseSupplySelection = true
                        }) {
                            HStack {
                                Text(chosenProduct != nil ? "Выбрано: \(chosenProduct?.name ?? "")" : "Выбрать поставку")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Приход/Расход")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imagePickerSourceType, image: $productImage)
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { scannedCode in
                    barcode = scannedCode
                    showingBarcodeScanner = false
                    autoFillProductData()
                }
            }
            .sheet(isPresented: $showExpenseSupplySelection) {
                ExpenseSupplySelectionView { selected in
                    chosenProduct = selected
                    showExpenseSupplySelection = false
                    showExpenseDetailSheet = true
                }
            }
            .sheet(isPresented: $showExpenseDetailSheet) {
                if let product = chosenProduct {
                    ExpenseSupplyDetailView(product: product) { prod, qty, purpose in
                        processExpense(for: prod, quantity: qty, expensePurpose: purpose)
                        showExpenseDetailSheet = false
                        chosenProduct = nil
                    }
                }
            }
        }
    }
    
    private func actionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            buttons.append(.default(Text("Сделать фото")) {
                imagePickerSourceType = .camera
                showingImagePicker = true
            })
        }
        buttons.append(.default(Text("Выбрать из галереи")) {
            imagePickerSourceType = .photoLibrary
            showingImagePicker = true
        })
        buttons.append(.cancel())
        return buttons
    }
    
    private func autoFillProductData() {
        guard !barcode.isEmpty else { return }
        let request: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
        request.predicate = NSPredicate(format: "barcode == %@", barcode)
        do {
            if let existingProduct = try viewContext.fetch(request).first {
                productName = existingProduct.name ?? ""
                organization = existingProduct.organization ?? ""
                price = existingProduct.price != 0 ? String(existingProduct.price) : ""
                quantity = String(existingProduct.quantity)
                category = existingProduct.category ?? ""
                target = existingProduct.target ?? ""
                if let data = existingProduct.photo, let image = UIImage(data: data) {
                    productImage = image
                }
            }
        } catch {
            print("Ошибка автозаполнения: \(error)")
        }
    }
    
    private func saveTransactionQuickExpense() {
        guard let qty = Int64(quantity) else {
            print("Неверное значение количества")
            return
        }
        
        if transactionType == "Приход" {
            let newProduct = ProductItem(context: viewContext)
            newProduct.id = UUID()
            newProduct.name = productName
            newProduct.organization = organization
            newProduct.price = Double(price) ?? 0
            newProduct.quantity = qty
            newProduct.category = category
            newProduct.target = target
            newProduct.barcode = barcode
            if let image = productImage, let data = image.jpegData(compressionQuality: 0.8) {
                newProduct.photo = data
            }
            newProduct.container = selectedContainer
            
            var customDict: [String: String] = [:]
            for field in customFields {
                if !field.value.isEmpty {
                    customDict[field.name] = field.value
                }
            }
            newProduct.customFields = customDict as NSObject
            
            let newTransaction = InventoryTransaction(context: viewContext)
            newTransaction.id = UUID()
            newTransaction.date = Date()
            newTransaction.type = transactionType
            newTransaction.product = newProduct
        } else if transactionType == "Расход" && expenseEntryMode == .quick {
            let request: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
            request.predicate = NSPredicate(format: "barcode == %@", barcode)
            do {
                let results = try viewContext.fetch(request)
                let candidates = results.filter { $0.quantity > 0 }
                if candidates.isEmpty {
                    let newProduct = ProductItem(context: viewContext)
                    newProduct.id = UUID()
                    newProduct.name = productName
                    newProduct.organization = organization
                    newProduct.price = Double(price) ?? 0
                    newProduct.quantity = 0
                    newProduct.category = category
                    newProduct.target = target
                    newProduct.barcode = barcode
                    if let image = productImage, let data = image.jpegData(compressionQuality: 0.8) {
                        newProduct.photo = data
                    }
                    newProduct.container = selectedContainer
                    
                    var customDict: [String: String] = [:]
                    for field in customFields {
                        if !field.value.isEmpty {
                            customDict[field.name] = field.value
                        }
                    }
                    newProduct.customFields = customDict as NSObject
                    
                    let newTransaction = InventoryTransaction(context: viewContext)
                    newTransaction.id = UUID()
                    newTransaction.date = Date()
                    newTransaction.type = transactionType
                    newTransaction.product = newProduct
                } else if candidates.count == 1 {
                    let productToDeduct = candidates.first!
                    productToDeduct.quantity = max(productToDeduct.quantity - qty, 0)
                    if productToDeduct.quantity == 0 {
                        productToDeduct.container = nil
                    }
                    let newTransaction = InventoryTransaction(context: viewContext)
                    newTransaction.id = UUID()
                    newTransaction.date = Date()
                    newTransaction.type = transactionType
                    newTransaction.product = productToDeduct
                } else {
                    print("Найдено несколько кандидатов, требуется выбор.")
                }
            } catch {
                print("Ошибка выборки существующего товара: \(error)")
            }
        }
        
        do {
            try viewContext.save()
            productName = ""
            organization = ""
            price = ""
            quantity = ""
            category = ""
            target = ""
            barcode = ""
            productImage = nil
            let savedCategoryOptions = UserDefaults.standard.stringArray(forKey: "CategoryOptions") ?? ["Электроника", "Продукты", "Одежда"]
            categoryOptions = savedCategoryOptions
            let savedTechniqueOptions = UserDefaults.standard.stringArray(forKey: "TechniqueOptions") ?? ["Компьютер", "Телефон", "Планшет"]
            techniqueOptions = savedTechniqueOptions
            let saved = UserDefaults.standard.stringArray(forKey: "CustomFields") ?? ["название", "организация", "цена"]
            customFields = saved.map { CustomField(name: $0, value: "") }
            selectedContainer = nil
        } catch {
            print("Ошибка сохранения транзакции: \(error)")
        }
    }
    
    private func processExpense(for product: ProductItem, quantity qty: Int64, expensePurpose: String) {
        guard qty > 0 else { return }
        guard product.quantity >= qty else {
            print("Недостаточно товара для списания")
            return
        }
        
        product.quantity -= qty
        if product.quantity == 0 {
            product.container = nil
        }
        
        let newTransaction = InventoryTransaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.date = Date()
        newTransaction.type = transactionType
        newTransaction.product = product
        newTransaction.expenseQuantity = qty
        newTransaction.expensePurpose = expensePurpose
        
        do {
            try viewContext.save()
        } catch {
            print("Ошибка сохранения транзакции: \(error)")
        }
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
