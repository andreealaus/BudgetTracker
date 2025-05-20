import SwiftUI
import CoreData

struct RapoarteSheetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var budgetManager: BudgetManager
    
    // FetchRequest pentru tranzacții din Core Data
    @FetchRequest(
        entity: TransactionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
    )
    var transactions: FetchedResults<TransactionEntity>
    
    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        VStack {
            Text("Rapoarte Lunare")
                .font(.headline)
                .padding(.bottom)
            
            // Selectarea lunii
            DatePicker("Selectează luna", selection: $selectedMonth, displayedComponents: [.date])
                .labelsHidden()
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            
            // Calcul veniturilor și cheltuielilor
            let monthlyIncome = totalIncome(for: selectedMonth)
            let monthlyExpense = totalExpense(for: selectedMonth)
            let net = monthlyIncome - monthlyExpense
            
            Text("Venituri: \(monthlyIncome, specifier: "%.2f")")
                .foregroundColor(.green)
                .padding(.top)
            Text("Cheltuieli: \(monthlyExpense, specifier: "%.2f")")
                .foregroundColor(.red)
            Text("Net: \(net, specifier: "%.2f")")
                .foregroundColor(.white)
                .padding(.bottom)
            
            Spacer()
        }
        .padding()
        .preferredColorScheme(.dark)
    }
    
    private func totalIncome(for month: Date) -> Double {
        guard let currentUser = budgetManager.currentUser else { return 0 }
        let monthlyTx = transactions.filter { tx in
            guard let catType = tx.category?.type?.lowercased(),
                  let user = tx.user else { return false }
            let sameMonth = Calendar.current.isDate(tx.date ?? Date(), equalTo: month, toGranularity: .month)
            return catType == "income" && user.familyID == currentUser.familyID && sameMonth
        }
        return monthlyTx.map { $0.totalAmount }.reduce(0, +)
    }
    
    private func totalExpense(for month: Date) -> Double {
        guard let currentUser = budgetManager.currentUser else { return 0 }
        let monthlyTx = transactions.filter { tx in
            guard let catType = tx.category?.type?.lowercased(),
                  let user = tx.user else { return false }
            let sameMonth = Calendar.current.isDate(tx.date ?? Date(), equalTo: month, toGranularity: .month)
            return catType == "expense" && user.familyID == currentUser.familyID && sameMonth
        }
        return monthlyTx.map { $0.totalAmount }.reduce(0, +)
    }
}

struct RapoarteSheetView_Previews: PreviewProvider {
    static var previews: some View {
        RapoarteSheetView()
            .environmentObject(BudgetManager())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
