import SwiftUI
import CoreData

struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetManager: BudgetManager

    // Date introduse de utilizator
    @State private var totalAmount: Double = 0.0
    @State private var selectedCategory: CategoryEntity? = nil
    @State private var transactionDetails: String = ""

    // Pentru alertă când nu există categorie
    @State private var showCategoryAlert = false

    // Pentru alertă când bugetul este depășit
    @State private var showBudgetExceededAlert = false
    @State private var exceededCategoryName = ""

    // Categoriile din Core Data
    @FetchRequest(
        entity: CategoryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)]
    ) var coreDataCategories: FetchedResults<CategoryEntity>

    private var numberFormatter: NumberFormatter {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        return fmt
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalii Tranzacție")) {
                    TextField("Suma Totală", value: $totalAmount, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                    TextField("Detalii (ex Cumparaturi supermarket, pranz, etc)", text: $transactionDetails)
                }

                Section(header: Text("Alocare Categorie")) {
                    // username‑ul curent
                    let currentUser = budgetManager.currentUser?.username
                    // adminul familiei (dacă există)
                    let familyAdmin = CoreDataUtils.fetchCurrentUserEntity(context: viewContext, username: budgetManager.currentUser?.username)?.createdBy

                    Picker("Categorie", selection: $selectedCategory) {
                        ForEach(
                            coreDataCategories.filter { category in
                                // includem și categoriile default (createdBy nil)
                                category.createdBy == nil
                                || category.createdBy == currentUser
                                || category.createdBy == familyAdmin
                            },
                            id: \.id
                        ) { category in
                            Text(category.name ?? "Necunoscut")
                                .tag(Optional(category))
                        }
                    }
                }

                Button("Adaugă Tranzacție") {
                    if selectedCategory == nil {
                        showCategoryAlert = true
                    } else {
                        addTransactionAndUpdatePlan()
                    }
                }
                .alert("Categorie necesară", isPresented: $showCategoryAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
            .navigationTitle("Adaugă Tranzacție")
            // Alertă dacă planul este depășit
            .alert("Atentionare Buget", isPresented: $showBudgetExceededAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Bugetul pentru „\(exceededCategoryName)” a fost depășit.")
            }
        }
        .onAppear {
            // Setăm categoria implicită la prima disponibilă
            if selectedCategory == nil {
                selectedCategory = coreDataCategories.first
            }
        }
    }

    private func addTransactionAndUpdatePlan() {
        guard let category = selectedCategory,
              let currentUser = budgetManager.currentUser else { return }

        // 1) Creăm și salvăm TransactionEntity
        let tx = TransactionEntity(context: viewContext)
        tx.id = UUID()
        tx.date = Date()
        tx.totalAmount = totalAmount
        tx.note = transactionDetails.isEmpty ? "Adăugată manual" : transactionDetails
        tx.category = category

        // Asociem UserEntity-ul (admin sau regular)
        let req: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        req.predicate = NSPredicate(format: "username == %@", currentUser.username)
        if let userEntity = try? viewContext.fetch(req).first {
            tx.user = userEntity
        }

        do {
            try viewContext.save()
        } catch {
            print("⚠️ Eroare la salvarea tranzacției: \(error)")
            return
        }

        let planOwner: String
        if let userEntity = (selectedCategory == nil ? nil : CoreDataUtils.fetchCurrentUserEntity(context: viewContext, username: budgetManager.currentUser?.username)),
           let createdBy = userEntity.createdBy {
            planOwner = createdBy
        } else {
            planOwner = budgetManager.currentUser?.username ?? ""
        }
        // 2) Actualizăm planul de buget asociat categoriei
        updateBudgetPlan(for: category, addedAmount: totalAmount, planOwner: planOwner, context: viewContext)
    }

    public func updateBudgetPlan(for category: CategoryEntity, addedAmount: Double, planOwner: String, context: NSManagedObjectContext) {
        
        // Căutăm planul cu titlul = nume categorie și createdBy = planOwner, unde luna corepunde
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? Date()

        let planReq: NSFetchRequest<BudgetPlanEntity> = BudgetPlanEntity.fetchRequest()
        planReq.predicate = NSPredicate(format: "title == %@ AND createdBy == %@ AND date >= %@ AND date < %@", category.name ?? "", planOwner, startOfMonth as NSDate, endOfMonth as NSDate)

        do {
            if let plan = try context.fetch(planReq).first {
                plan.progress += addedAmount
                exceededCategoryName = category.name ?? ""
                let exceeded = plan.progress > plan.amount
                try context.save()
                if exceeded {
                    // Afișăm alerta de depășire
                    showBudgetExceededAlert = true
                } else {
                    // Dacă n-a depășit, închidem sheet-ul direct
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                // Nu există plan pentru această categorie / utilizator: doar închidem
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            print("⚠️ Eroare la actualizarea planului: \(error)")
            presentationMode.wrappedValue.dismiss()
        }
    }
}
