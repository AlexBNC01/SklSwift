import SwiftUI
import CoreData
import FirebaseFirestore
import FirebaseAuth

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
    @State private var technique: String = ""
    @State private var barcode: String = ""
    @State private var productImage: UIImage? = nil
    
    // Флаги для выбора фото
    @State private var showingImagePicker: Bool = false
    @State private var showPhotoOptions: Bool = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // Дополнительные поля – загружаются из UserDefaults
    @State private var customFields: [CustomField] = {
        let saved = UserDefaults.standard.stringArray(forKey: "CustomFields") ?? ["название", "организация", "цена"]
        return saved.map { CustomField(name: $0, value: "") }
    }()
    
    // Опции для выпадающих списков
    @State private var categoryOptions: [String] = UserDefaults.standard.stringArray(forKey: "CategoryOptions") ?? ["Электроника", "Продукты", "Одежда"]
    @State private var techniqueOptions: [String] = UserDefaults.standard.stringArray(forKey: "TechniqueOptions") ?? ["Компьютер", "Телефон", "Планшет"]
    
    // Дополнительные переменные
    @State private var filteredProducts: [ProductItem] = []  // Используется для автозаполнения
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
    
    // Статус сообщения для пользователя
    @State private var statusMessage: String = ""
    
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
                
                // Блок для режима "Приход" или "Быстрый расход"
                if transactionType == "Приход" || (transactionType == "Расход" && expenseEntryMode == .quick) {
                    Section(header: Text("Информация о товаре")) {
                        TextField("Название", text: $productName)
                            .onChange(of: productName) { newValue in
                                filteredProducts = allProducts.filter { $0.name?.contains(newValue) == true }
                            }
                        
                        // Автоподсказка по наименованию
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
                        
                        HStack {
                            TextField("Категория", text: $category)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Menu {
                                ForEach(categoryOptions, id: \.self) { option in
                                    Button(option) { category = option }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        HStack {
                            TextField("Техника", text: $technique)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Menu {
                                ForEach(techniqueOptions, id: \.self) { option in
                                    Button(option) { technique = option }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        HStack {
                            TextField("Штрих-код", text: $barcode)
                                .disabled(true)
                            Button(action: { showingBarcodeScanner = true }) {
                                Image(systemName: "barcode.viewfinder")
                            }
                        }
                        
                        Button(action: { showPhotoOptions = true }) {
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
                            ActionSheet(
                                title: Text("Выберите источник"),
                                buttons: actionSheetButtons()
                            )
                        }
                    }
                    
                    Section(header: Text("Выбор контейнера")) {
                        Picker("Контейнер", selection: $selectedContainer) {
                            Text("Без контейнера").tag(WarehouseContainer?.none)
                            ForEach(availableContainers, id: \.id) { container in
                                Text(container.name ?? "Без названия").tag(Optional(container))
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
                }
                
                // Блок для режима "Расход" + "Выбрать поставку"
                else if transactionType == "Расход" && expenseEntryMode == .choose {
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
                
                // Сообщение пользователю
                if !statusMessage.isEmpty {
                    Section {
                        Text(statusMessage)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Приход/Расход")
            // Сканер штрих-кодов
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { scannedCode in
                    barcode = scannedCode
                    showingBarcodeScanner = false
                    autoFillProductData()
                }
            }
            // Выбор товара для списания
            .sheet(isPresented: $showExpenseSupplySelection) {
                ExpenseSupplySelectionView { selected in
                    chosenProduct = selected
                    showExpenseSupplySelection = false
                    showExpenseDetailSheet = true
                }
            }
            // Ввод количества и причины списания
            .sheet(isPresented: $showExpenseDetailSheet) {
                if let product = chosenProduct {
                    ExpenseSupplyDetailView(product: product) { chosen, qty, purpose in
                        confirmExpense(product: chosen, quantity: qty, purpose: purpose)
                        showExpenseDetailSheet = false
                        chosenProduct = nil
                    }
                }
            }
            // Sheet для показа ImagePicker
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imagePickerSourceType, image: $productImage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
        if let user = Auth.auth().currentUser {
            request.predicate = NSPredicate(format: "barcode == %@ AND ownerId == %@", barcode, user.uid)
        } else {
            request.predicate = NSPredicate(format: "barcode == %@ AND ownerId == nil", barcode)
        }
        do {
            if let existingProduct = try viewContext.fetch(request).first {
                productName = existingProduct.name ?? ""
                organization = existingProduct.organization ?? ""
                price = existingProduct.price != 0 ? String(existingProduct.price) : ""
                quantity = String(existingProduct.quantity)
                category = existingProduct.category ?? ""
                technique = existingProduct.target ?? ""
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
            newProduct.target = technique
            newProduct.barcode = barcode
            if let image = productImage, let data = image.jpegData(compressionQuality: 0.8) {
                newProduct.photo = data
            }
            newProduct.container = selectedContainer
            
            // Если пользователь авторизован – сохраняем uid
            if let user = Auth.auth().currentUser {
                newProduct.ownerId = user.uid
            }
            
            var customDict: [String: String] = [:]
            for field in customFields {
                if !field.value.isEmpty {
                    customDict[field.name] = field.value
                }
            }
            newProduct.customFields = customDict as NSDictionary
            
            let newTransaction = InventoryTransaction(context: viewContext)
            newTransaction.id = UUID()
            newTransaction.date = Date()
            newTransaction.type = transactionType
            newTransaction.product = newProduct
            if let user = Auth.auth().currentUser {
                newTransaction.ownerId = user.uid
            }
            
            do {
                try viewContext.save()
                statusMessage = "Операция сохранена локально!"
                
                if let user = Auth.auth().currentUser {
                    // Сохраняем товар в Firebase
                    FirestoreService.shared.saveOrUpdateProduct(product: newProduct,
                                                                for: user,
                                                                image: productImage) { error in
                        if let error = error {
                            statusMessage += "\nОшибка сохранения товара в Firebase: \(error.localizedDescription)"
                        } else {
                            statusMessage += "\nТовар сохранён в Firebase."
                        }
                    }
                    // Сохраняем транзакцию в Firebase
                    FirestoreService.shared.saveTransaction(newTransaction, for: user) { error in
                        if let error = error {
                            statusMessage += "\nОшибка сохранения транзакции в Firebase: \(error.localizedDescription)"
                        } else {
                            statusMessage += "\nТранзакция сохранена в Firebase."
                        }
                    }
                }
            } catch {
                print("Ошибка сохранения транзакции: \(error)")
            }
            
        } else if transactionType == "Расход" && expenseEntryMode == .quick {
            guard !barcode.isEmpty else {
                statusMessage = "Штрих-код не задан, невозможно выполнить списание."
                return
            }
            let request: NSFetchRequest<ProductItem> = ProductItem.fetchRequest()
            if let user = Auth.auth().currentUser {
                request.predicate = NSPredicate(format: "barcode == %@ AND ownerId == %@", barcode, user.uid)
            } else {
                request.predicate = NSPredicate(format: "barcode == %@ AND ownerId == nil", barcode)
            }
            do {
                let results = try viewContext.fetch(request)
                let candidates = results.filter { $0.quantity > 0 }
                if candidates.isEmpty {
                    statusMessage = "Товар для списания не найден или его количество равно нулю."
                } else if candidates.count == 1 {
                    let productToDeduct = candidates.first!
                    if qty > productToDeduct.quantity {
                        statusMessage = "Недостаточно товара для списания."
                        return
                    }
                    productToDeduct.quantity -= qty
                    
                    let newTransaction = InventoryTransaction(context: viewContext)
                    newTransaction.id = UUID()
                    newTransaction.date = Date()
                    newTransaction.type = transactionType
                    newTransaction.product = productToDeduct
                    newTransaction.expenseQuantity = qty
                    newTransaction.expensePurpose = "Быстрый расход"
                    if let user = Auth.auth().currentUser {
                        newTransaction.ownerId = user.uid
                    }
                    
                    try viewContext.save()
                    statusMessage = "Операция сохранена локально!"
                    
                    if let user = Auth.auth().currentUser {
                        // Обновляем товар в Firebase
                        FirestoreService.shared.saveOrUpdateProduct(product: productToDeduct,
                                                                    for: user,
                                                                    image: productImage) { error in
                            if let error = error {
                                statusMessage += "\nОшибка обновления товара в Firebase: \(error.localizedDescription)"
                            } else {
                                statusMessage += "\nТовар обновлён в Firebase."
                            }
                        }
                        // Сохраняем транзакцию в Firebase
                        FirestoreService.shared.saveTransaction(newTransaction, for: user) { error in
                            if let error = error {
                                statusMessage += "\nОшибка сохранения транзакции в Firebase: \(error.localizedDescription)"
                            } else {
                                statusMessage += "\nТранзакция сохранена в Firebase."
                            }
                        }
                    }
                } else {
                    statusMessage = "Найдено несколько кандидатов, требуется выбор."
                }
            } catch {
                statusMessage = "Ошибка выборки товара: \(error.localizedDescription)"
            }
        }
    }
    
    private func confirmExpense(product: ProductItem, quantity: Int64, purpose: String) {
        guard product.quantity >= quantity else {
            statusMessage = "Недостаточно остатков для списания."
            return
        }
        
        product.quantity -= quantity
        
        let newTransaction = InventoryTransaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.date = Date()
        newTransaction.type = "Расход"
        newTransaction.expenseQuantity = quantity
        newTransaction.expensePurpose = purpose
        newTransaction.product = product
        if let user = Auth.auth().currentUser {
            newTransaction.ownerId = user.uid
        }
        
        do {
            try viewContext.save()
            statusMessage = "Расход успешно сохранён!"
            
            if let user = Auth.auth().currentUser {
                // Обновляем товар в Firebase
                FirestoreService.shared.saveOrUpdateProduct(product: product, for: user, image: nil) { error in
                    if let error = error {
                        statusMessage += "\nОшибка обновления товара в Firebase: \(error.localizedDescription)"
                    } else {
                        statusMessage += "\nТовар обновлён в Firebase."
                    }
                }
                // Сохраняем транзакцию в Firebase
                FirestoreService.shared.saveTransaction(newTransaction, for: user) { error in
                    if let error = error {
                        statusMessage += "\nОшибка сохранения транзакции в Firebase: \(error.localizedDescription)"
                    } else {
                        statusMessage += "\nТранзакция сохранена в Firebase."
                    }
                }
            }
            
        } catch {
            print("Ошибка сохранения транзакции: \(error)")
            statusMessage = "Ошибка сохранения транзакции: \(error.localizedDescription)"
        }
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
