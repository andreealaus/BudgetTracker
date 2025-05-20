import Foundation
import Combine
import CoreData  // Adăugăm import CoreData

class BudgetManager: ObservableObject {
    @Published var users: [User] = []
    @Published var categories: [Category] = []
    @Published var transactions: [Transaction] = []
    @Published var budgetPlans: [BudgetPlan] = []
    
    // Utilizatorul curent logat
    @Published var currentUser: User?
    
    // Adăugăm un context Core Data
    var context: NSManagedObjectContext?
    
    // Constructor care primește contextul
    init(context: NSManagedObjectContext? = nil) {
        self.context = context
    }
    
    // Creare utilizator (doar adminul poate crea utilizatori noi)
    func createUser(by admin: User, username: String, role: UserRole = .regular) -> User? {
        guard admin.role == .admin else {
            print("Doar adminul poate crea utilizatori noi.")
            return nil
        }
        if users.contains(where: { $0.username == username }) {
            print("Username-ul există deja.")
            return nil
        }
        let newUser = User(username: username, role: role)
        users.append(newUser)
        return newUser
    }
    
    // Creare utilizator de tip Admin
    func createAdminUser(by admin: User, username: String) -> User? {
        guard admin.role == .admin else {
            print("Doar adminul poate crea utilizatori admin.")
            return nil
        }
        if users.contains(where: { $0.username == username }) {
            print("Username-ul există deja.")
            return nil
        }
        let newAdmin = User(username: username, role: .admin)
        users.append(newAdmin)
        return newAdmin
    }
    
    // Adăugare categorie (doar adminul)
    func addCategory(by admin: User, name: String, type: CategoryType) -> Category? {
        guard admin.role == .admin else {
            print("Doar adminul poate adăuga categorii.")
            return nil
        }
        let newCategory = Category(name: name, type: type)
        categories.append(newCategory)
        return newCategory
    }
    
    // Configurare plan lunar
    func setupMonthlyBudgetPlan(by admin: User,
                                for month: Date,
                                categoryAllocations: [Category: Double],
                                userAllocations: [User: Double]) -> BudgetPlan? {
        guard admin.role == .admin else {
            print("Doar adminul poate configura bugetul lunar.")
            return nil
        }
        let plan = BudgetPlan(month: month,
                              categoryAllocations: categoryAllocations,
                              userAllocations: userAllocations)
        budgetPlans.append(plan)
        return plan
    }
    
    // MARK: - Adăugare tranzacție (modificat pentru a salva și în Core Data)
    func addTransaction(by user: User,
                        totalAmount: Double,
                        categoryAllocations: [Category: Double]) -> Transaction {
        // 1) Creăm obiectul Transaction (în memorie) pentru logica existentă
        let transaction = Transaction(user: user,
                                      date: Date(),
                                      totalAmount: totalAmount,
                                      categoryAllocations: categoryAllocations)
        transactions.append(transaction)
        
        // 2) Salvăm și în Core Data (dacă avem context)
        if let context = context {
            let newTxEntity = TransactionEntity(context: context)
            newTxEntity.id = UUID()
            newTxEntity.date = transaction.date
            newTxEntity.totalAmount = transaction.totalAmount
            // Dacă ai logica de a salva user, category etc. în Core Data,
            // trebuie să găsești UserEntity și CategoryEntity corespunzătoare și să le setezi.
            // Ex: newTxEntity.user = ...
            // Ex: newTxEntity.category = ...
            
            do {
                try context.save()
                print("Tranzacție salvată în Core Data: \(transaction.totalAmount)")
            } catch {
                print("Eroare la salvarea tranzacției: \(error)")
            }
        }
        
        return transaction
    }
    
    // Calcul buget rămas într-o categorie pentru o lună
    func remainingBudget(for category: Category, in month: Date) -> Double {
        guard let plan = budgetPlans.first(where: {
            Calendar.current.isDate($0.month, equalTo: month, toGranularity: .month)
        }) else {
            return 0.0
        }
        let allocated = plan.categoryAllocations[category] ?? 0.0
        let spent = transactions
            .filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
            .map { $0.categoryAllocations[category] ?? 0.0 }
            .reduce(0, +)
        return allocated - spent
    }
    
    // Generare raport lunar
    func generateMonthlyReport(for month: Date) -> String {
        var report = "Raport lunar pentru \(month):\n"
        for category in categories {
            let allocated = budgetPlans.first(where: {
                Calendar.current.isDate($0.month, equalTo: month, toGranularity: .month)
            })?.categoryAllocations[category] ?? 0.0
            
            let spent = transactions
                .filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
                .map { $0.categoryAllocations[category] ?? 0.0 }
                .reduce(0, +)
            
            report += "\(category.name): alocat \(allocated), cheltuit \(spent), rămas \(allocated - spent)\n"
        }
        return report
    }
}
