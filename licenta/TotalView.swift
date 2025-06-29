import SwiftUI
import CoreData

struct TotalView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.managedObjectContext) private var viewContext
    
    // Tranzacțiile filtrate transmise din DashboardView
    var transactions: [TransactionEntity]
    
    // Variabilă pentru luna selectată
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    
    var body: some View {
        NavigationView {
            VStack {
                // Picker cu meniul lunilor
                Menu {
                    ForEach(1..<13, id: \.self) { month in
                        Button(action: {
                            selectedMonth = month
                        }) {
                            Text(CoreDataUtils.monthName(for: month))
                        }
                    }
                } label: {
                    Text("Alege luna: \(CoreDataUtils.monthName(for: selectedMonth))")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                
                // Filtrăm tranzacțiile în funcție de luna selectată
                let filteredTransactions = transactions.filter { tx in
                    guard let date = tx.date else { return false }
                    let month = Calendar.current.component(.month, from: date)
                    return month == selectedMonth
                }
                
                // Calculăm suma totală a tranzacțiilor pentru familia utilizatorului curent
                let totalAmount = filteredTransactions
                    .filter { tx in
                        guard let category = tx.category else { return false }
                        return category.type == "expense"
                    }
                    .map { $0.totalAmount }
                    .reduce(0, +)
                
                Text("Suma totală cheltuită: \(totalAmount, specifier: "%.2f")")
                    .font(.headline)
                    .padding()
                
                List(filteredTransactions, id: \.id) { tx in
                    VStack(alignment: .leading) {
                        Text("Sumă: \(tx.totalAmount, specifier: "%.2f")")
                        
                        if let date = tx.date {
                            Text("Data: \(date, style: .date)")
                                .font(.caption)
                        }
                        
                        // Afișăm categoria tranzacției
                        if let category = tx.category {
                            Text("Categorie: \(category.name ?? "Necunoscută")")
                                .font(.footnote)
                        }
                        
                        // Afișăm utilizatorul care a adăugat tranzacția
                        if let user = tx.user {
                            Text("Adăugat de: \(user.username ?? "Necunoscut")")
                                .font(.footnote)
                                .foregroundColor(.green)
                        }
                        
                        // Afișăm nota tranzacției
                        if let note = tx.note, !note.isEmpty {
                            Text("Note: \(note)")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    }
                    .contextMenu {
                        Button(action: {
                            deleteTransaction(transaction: tx)
                        }) {
                            Text("Șterge tranzacția")
                            Image(systemName: "trash")
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .navigationTitle("Tranzacții lunare")
        }
    }
    
    // Funcție pentru ștergerea tranzacției și actualizarea planului bugetar
    private func deleteTransaction(transaction: TransactionEntity) {
        do {
            try viewContext.save()

            // Actualizăm planul bugetar după ștergerea tranzacției
            guard let category = transaction.category else {
                print("⚠️ Categoria tranzacției este nil. Nu se poate actualiza planul bugetar.")
                return
            }

            let planOwner: String
            if let userEntity = CoreDataUtils.fetchCurrentUserEntity(context: viewContext, username: budgetManager.currentUser?.username),
            let createdBy = userEntity.createdBy {
                planOwner = createdBy
            } else {
                planOwner = budgetManager.currentUser?.username ?? ""
            }

            let addTransactionView = AddTransactionView()
            addTransactionView.updateBudgetPlan(
                for: category,
                addedAmount: -transaction.totalAmount,
                planOwner: planOwner,
                context: viewContext
            )
            viewContext.delete(transaction)

            print("Tranzacție ștearsă și planul bugetar actualizat.")
        } catch {
            print("Eroare la ștergerea tranzacției: \(error)")
        }
    }
}

struct TotalView_Previews: PreviewProvider {
    static var previews: some View {
        TotalView(transactions: [])
            .environmentObject(BudgetManager())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
