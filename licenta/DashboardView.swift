import SwiftUI

struct DashboardView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var selectedTab = 0
    @State private var showAddTransaction = false
    @State private var showOCRView = false

    // FetchRequest pentru tranzacțiile gestionate de Core Data
    @FetchRequest(entity: TransactionEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: true)])
    var allTransactions: FetchedResults<TransactionEntity>

    // Calculăm tranzacțiile filtrate în funcție de utilizatorul curent
    var filteredTransactions: [TransactionEntity] {
        guard let currentUser = budgetManager.currentUser else { return [] }
        if currentUser.role == .admin {
            // Pentru admin: afișăm tranzacțiile lui și ale utilizatorilor din familia lui
            return allTransactions.filter { transaction in
                transaction.user?.username == currentUser.username || transaction.user?.createdBy == currentUser.username
            }
        } else {
            // Pentru utilizatorii regulari: doar tranzacțiile utilizatorului curent
            return allTransactions.filter { transaction in
                transaction.user?.username == currentUser.username
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                DailyView(transactions: filteredTransactions) 
                    .tabItem {
                        Image(systemName: "arrow.up.circle")
                        Text("Cheltuieli")
                    }
                    .tag(0)

                MonthlyView(transactions: filteredTransactions) 
                    .tabItem {
                        Image(systemName: "arrow.down.circle")
                        Text("Venituri")
                    }
                    .tag(1)

                CalendarView(transactions: filteredTransactions) 
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Tranzacții zilnice")
                    }
                    .tag(2)

                TotalView(transactions: filteredTransactions) 
                    .tabItem {
                        Image(systemName: "sum")
                        Text("Tranzacții lunare")
                    }
                    .tag(3)
            }
            .accentColor(.orange)
            
            Button(action: {
                showAddTransaction = true
            }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 75)
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
                    .environmentObject(budgetManager)
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showOCRView = true
                } label: {
                    Image(systemName: "doc.text.viewfinder")
                }
            }
        }
        .sheet(isPresented: $showOCRView) {
            OCRView().environmentObject(budgetManager)
        }
    }

}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView().environmentObject(BudgetManager())
        }
    }
}
