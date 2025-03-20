import SwiftUI
import CoreData
import FirebaseAuth

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        // Формируем predicate на основе ownerId:
        // Если пользователь авторизован – отображаем транзакции с ownerId равным uid,
        // иначе – транзакции без привязки (ownerId == nil)
        let predicate: NSPredicate = {
            if let user = sessionManager.currentUser {
                print("HistoryView: predicate = ownerId == \(user.uid)")
                return NSPredicate(format: "ownerId == %@", user.uid)
            } else {
                print("HistoryView: predicate = ownerId == nil")
                return NSPredicate(format: "ownerId == nil")
            }
        }()
        
        return HistoryContentView(predicate: predicate)
            .id(sessionManager.currentUser?.uid ?? "guest")
            .onAppear {
                guard let user = sessionManager.currentUser else {
                    // Гость: просто обновим контекст и выведем локальные guest-данные
                    viewContext.refreshAllObjects()
                    let count = fetchTransactionCount(predicate: predicate)
                    print("HistoryView appeared (guest). Transactions count: \(count)")
                    return
                }
                
                // Если пользователь авторизован – загружаем последние 25 транзакций из Firestore
                FirestoreService.shared.fetchLast25Transactions(for: user) { items, error in
                    if let error = error {
                        print("Ошибка при загрузке последних 25 транзакций: \(error)")
                        // Тем не менее, обновим контекст, чтобы показать локальные
                        DispatchQueue.main.async {
                            viewContext.refreshAllObjects()
                            let count = fetchTransactionCount(predicate: predicate)
                            print("HistoryView appeared. Transactions count (local only): \(count)")
                        }
                        return
                    }
                    // items – это [[String: Any]] с полями транзакций
                    SessionManager.shared.saveTransactionsDataToMainStore(items, ownerId: user.uid)
                    
                    // Обновляем контекст, чтобы список отобразил новые данные
                    DispatchQueue.main.async {
                        viewContext.refreshAllObjects()
                        let count = fetchTransactionCount(predicate: predicate)
                        print("HistoryView appeared. Transactions count (after fetchLast25): \(count)")
                    }
                }
            }
    }
    
    private func fetchTransactionCount(predicate: NSPredicate) -> Int {
        let request: NSFetchRequest<InventoryTransaction> = InventoryTransaction.fetchRequest()
        request.predicate = predicate
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Ошибка подсчёта транзакций: \(error)")
            return 0
        }
    }
}

struct HistoryContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var predicate: NSPredicate

    @FetchRequest var transactions: FetchedResults<InventoryTransaction>
    
    init(predicate: NSPredicate) {
        self.predicate = predicate
        _transactions = FetchRequest<InventoryTransaction>(
            entity: InventoryTransaction.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \InventoryTransaction.date, ascending: false)],
            predicate: predicate
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                if transactions.isEmpty {
                    Text("Нет транзакций")
                        .foregroundColor(.gray)
                }
                ForEach(transactions, id: \.id) { transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        TransactionCardView(transaction: transaction)
                    }
                }
                .onDelete(perform: deleteTransactions)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("История (\(transactions.count))")
        }
    }
    
    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = transactions[index]
            viewContext.delete(transaction)
        }
        do {
            try viewContext.save()
        } catch {
            print("Ошибка удаления транзакции: \(error)")
        }
    }
}

struct TransactionCardView: View {
    var transaction: InventoryTransaction
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let product = transaction.product,
               let photoData = product.photo,
               let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.product?.name ?? "Неизвестный товар")
                    .font(.headline)
                Text(transaction.type ?? "")
                    .font(.subheadline)
                    .foregroundColor(transaction.type == "Приход" ? .green : .red)
                
                if transaction.type == "Приход" {
                    if let product = transaction.product {
                        Text("Количество: \(product.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if transaction.type == "Расход" {
                    Text("Списано: \(transaction.expenseQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let purpose = transaction.expensePurpose, !purpose.isEmpty {
                        Text("Причина: \(purpose)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let date = transaction.date {
                    Text(date, formatter: itemFormatter)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
