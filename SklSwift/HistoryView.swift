import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: InventoryTransaction.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryTransaction.date, ascending: false)]
    ) var transactions: FetchedResults<InventoryTransaction>

    var body: some View {
        NavigationView {
            List {
                ForEach(transactions, id: \.id) { transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        TransactionCardView(transaction: transaction)
                    }
                }
                .onDelete(perform: deleteTransactions)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("История")
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

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
