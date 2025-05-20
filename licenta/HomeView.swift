import SwiftUI

struct HomeView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        if let currentUser = budgetManager.currentUser {
            if currentUser.role == .admin {
                AdminPanelView()
            } else {
                DashboardView()
            }
        } else {
            Text("Nu este niciun utilizator logat.")
                .foregroundColor(.gray)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(BudgetManager())
    }
}
