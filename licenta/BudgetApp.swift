import SwiftUI

@main
struct BudgetApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var budgetManager: BudgetManager

    init() {
        // Inițializează BudgetManager cu contextul Core Data
        let context = persistenceController.container.viewContext
        _budgetManager = StateObject(wrappedValue: BudgetManager(context: context))
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(budgetManager) // pentru currentUser & logic
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    persistenceController.loadDemoData()
                }
                .accentColor(.orange)
                .preferredColorScheme(.dark)
        }
    }
}
