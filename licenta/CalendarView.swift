import SwiftUI
import CoreData

struct CalendarView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.managedObjectContext) private var viewContext

    // Tranzacțiile filtrate transmise din DashboardView
    var transactions: [TransactionEntity]
    
    @State private var selectedDate: Date = Date()
    @State private var isCalendarExpanded: Bool = false // Starea de expansiune a calendarului

    var body: some View {
        NavigationView {
            VStack {
                // Buton pentru a arăta/ascunde calendarul
                DisclosureGroup(isExpanded: $isCalendarExpanded) {
                    DatePicker("Selectează Data", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                } label: {
                    Text("Selectează Data")
                        .font(.headline)
                        .padding()
                }

                let dailyTransactions = filteredTransactions(for: selectedDate)
                if dailyTransactions.isEmpty {
                    Text("Nu există tranzacții pentru această zi.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(dailyTransactions, id: \.id) { tx in
                            VStack(alignment: .leading) {
                                Text("Sumă: \(tx.totalAmount, specifier: "%.2f")")
                                
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
            .navigationTitle("Calendar")
        }
    }

    // Filtrarea tranzacțiilor pentru data selectată
    private func filteredTransactions(for date: Date) -> [TransactionEntity] {
        guard let currentUser = budgetManager.currentUser else { return [] }
        return transactions.filter { tx in
            guard let user = tx.user else { return false }
            let isSameDay = Calendar.current.isDate(tx.date ?? Date(), inSameDayAs: date)
            return isSameDay && user.familyID == currentUser.familyID
        }
    }

    // Funcție pentru ștergerea tranzacției
    private func deleteTransaction(transaction: TransactionEntity) {
        viewContext.delete(transaction)
        do {
            try viewContext.save()
            print("Tranzacție ștearsă")
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

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(transactions: [])
            .environmentObject(BudgetManager())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
