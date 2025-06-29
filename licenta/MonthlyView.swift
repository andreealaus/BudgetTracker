import SwiftUI
import CoreData

struct MonthlyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var selectedMonth: Date = Date()
    @State private var isCalendarExpanded: Bool = false // Starea de expansiune a calendarului

    // Tranzacțiile filtrate transmise din DashboardView
    var transactions: [TransactionEntity]

    var body: some View {
        NavigationView {
            VStack {
                // Buton pentru a arăta/ascunde calendarul
                DisclosureGroup(isExpanded: $isCalendarExpanded) {
                    
                    Menu {
                        ForEach(1..<13, id: \.self) { month in
                            Button(action: {
                                var components = Calendar.current.dateComponents([.year], from: Date())
                                components.month = month
                                selectedMonth = Calendar.current.date(from: components) ?? Date()
            
                            }) {
                                Text(CoreDataUtils.monthName(for: month))
                            }
                        }
                    } label: {
                        Text("Alege luna: \(CoreDataUtils.monthName(for: Calendar.current.component(.month, from:selectedMonth)))")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                } label: {
                    Text("Selectează luna")
                        .font(.headline)
                        .padding()
                }

                let monthlyIncomes = filteredIncomes(for: selectedMonth)
                if monthlyIncomes.isEmpty {
                    Text("Nu există venituri pentru această lună.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(monthlyIncomes, id: \.id) { tx in
                            VStack(alignment: .leading) {
                                Text("Sumă: \(tx.totalAmount, specifier: "%.2f")")
                                    .foregroundColor(.green)
                                
                                if let date = tx.date {
                                    Text("Data: \(date, style: .date)")
                                        .font(.caption)
                                }
                                
                                if let note = tx.note, !note.isEmpty {
                                    Text("Note: \(note)")
                                        .font(.footnote)
                                        .foregroundColor(.blue)
                                }
                                
                                if let category = tx.category {
                                    Text("Categorie: \(category.name ?? "Necunoscută")")
                                        .font(.footnote)
                                }
                                
                                // Afișează utilizatorul care a adăugat tranzacția
                                if let user = tx.user {
                                    Text("Adăugat de: \(user.username ?? "Necunoscut")")
                                        .font(.footnote)
                                        .foregroundColor(.green)
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
                    }
                    .listStyle(PlainListStyle())
                }
                Spacer()
            }
            .navigationTitle("Venituri")
        }
    }

    private func filteredIncomes(for month: Date) -> [TransactionEntity] {
        guard let currentUser = budgetManager.currentUser else { return [] }
        return transactions.filter { tx in
            guard let type = tx.category?.type?.lowercased(), let user = tx.user else { return false }
            let inSameMonth = Calendar.current.isDate(tx.date ?? Date(), equalTo: month, toGranularity: .month)
            return type == "income" && user.familyID == currentUser.familyID && inSameMonth
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

    // Funcție pentru editarea tranzacției (poți deschide o fereastră de editare)
    private func editTransaction(transaction: TransactionEntity) {
        print("Editează tranzacția: \(transaction.id ?? UUID())")
        // Exemplu: deschide un nou view pentru editare
    }
}

struct MonthlyView_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyView(transactions: [])
            .environmentObject(BudgetManager())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}

