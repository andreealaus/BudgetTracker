import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BudgetAppModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func loadDemoData() {
        let context = container.viewContext
        
        // Verificăm dacă există deja date (ex. un user)
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                print("Inserting demo data in Core Data...")
                
                // Creăm un admin demo
                let admin = UserEntity(context: context)
                admin.id = UUID()
                admin.username = "Andreea_admin"
                admin.role = "admin"
                admin.password = "admin123"
                
                // Creăm useri regular adăugați de adminul "Andreea_admin"
                let user1 = UserEntity(context: context)
                user1.id = UUID()
                user1.username = "Alex"
                user1.role = "regular"
                user1.password = "user123"
                user1.createdBy = admin.username
                
                let user2 = UserEntity(context: context)
                user2.id = UUID()
                user2.username = "Maria"
                user2.role = "regular"
                user2.password = "user1234"
                user2.createdBy = admin.username
                
                // MARK: - Categorii
                let rentCategory = CategoryEntity(context: context)
                rentCategory.id = UUID()
                rentCategory.name = "Locuinta"
                rentCategory.type = "expense"
                rentCategory.createdBy = admin.username
                
                let salaryCategory = CategoryEntity(context: context)
                salaryCategory.id = UUID()
                salaryCategory.name = "Salariu"
                salaryCategory.type = "income"
                salaryCategory.createdBy = admin.username
                
                let allowanceCategory = CategoryEntity(context: context)
                allowanceCategory.id = UUID()
                allowanceCategory.name = "Alocație"
                allowanceCategory.type = "income"
                allowanceCategory.createdBy = admin.username
                
                let productsCategory = CategoryEntity(context: context)
                productsCategory.id = UUID()
                productsCategory.name = "Alimente"
                productsCategory.type = "expense"
                productsCategory.createdBy = admin.username
                
                // MARK: - Tranzacții de test
                let salaryTx = TransactionEntity(context: context)
                salaryTx.id = UUID()
                salaryTx.date = Date()
                salaryTx.totalAmount = 4000.0
                salaryTx.note = "Salariu luna iunie"
                salaryTx.user = admin
                salaryTx.category = salaryCategory
                
                let allowanceTx = TransactionEntity(context: context)
                allowanceTx.id = UUID()
                allowanceTx.date = Date()
                allowanceTx.totalAmount = 200.0
                allowanceTx.note = "Alocație"
                allowanceTx.user = admin
                allowanceTx.category = allowanceCategory
                
                let rentTx = TransactionEntity(context: context)
                rentTx.id = UUID()
                rentTx.date = Date()
                rentTx.totalAmount = 1000.0
                rentTx.note = "Achitare chirie apartament"
                rentTx.user = user1
                rentTx.category = rentCategory
                
                let productTx = TransactionEntity(context: context)
                productTx.id = UUID()
                productTx.date = Date()
                productTx.totalAmount = 300.0
                productTx.note = "Cumpărat produse pentru casă"
                productTx.user = user2
                productTx.category = productsCategory
                
                try context.save()
                print("Demo data inserted successfully in Core Data.")
            } else {
                print("Demo data already loaded.")
            }
        } catch {
            print("Error loading or inserting demo data: \(error)")
        }
    }
}
