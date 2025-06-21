import SwiftUI
import CoreData

struct TotalView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    // Tranzacțiile filtrate transmise din DashboardView
    var transactions: [TransactionEntity]
    
    // Variabilă pentru luna selectată
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Total Overview")
                    .font(.title)
                    .padding()
                
                // Picker cu meniul lunilor
                Menu {
                    ForEach(1..<13, id: \.self) { month in
                        Button(action: {
                            selectedMonth = month
                        }) {
                            Text(monthName(for: month))
                        }
                    }
                } label: {
                    Text("Alege luna: \(monthName(for: selectedMonth))")
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
            .navigationTitle("Total")
        }
    }
    
    // Funcție pentru obținerea numelui lunii
    private func monthName(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        return dateFormatter.monthSymbols[month - 1]
    }

    // Funcție pentru ștergerea tranzacției
    private func deleteTransaction(transaction: TransactionEntity) {
        let context = PersistenceController.shared.container.viewContext
        context.delete(transaction)
        do {
            try context.save()
            print("Tranzacție ștearsă")
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
