import SwiftUI
import CoreData

struct AllTransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: TransactionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
    ) var transactions: FetchedResults<TransactionEntity>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(transactions, id: \.id) { tx in
                    VStack(alignment: .leading) {
                        Text("User: \(tx.user?.username ?? "Unknown")")
                        Text("Category: \(tx.category?.name ?? "Unknown")")
                        Text("Amount: \(tx.totalAmount, specifier: "%.2f")")
                        Text("Note: \(tx.note ?? "")")
                    }
                }
            }
            .navigationTitle("All Transactions")
        }
    }
}
