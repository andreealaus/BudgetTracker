import SwiftUI
import CoreData

struct AdminPanelView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // Flags
    @State private var showAddUser = false
    @State private var showAddCategory = false
    @State private var showPlanBudget = false
    @State private var showReports = false
    @State private var showAddReport = false

    // Formular de adaugare a userilor
    @State private var newUserName = ""
    @State private var newUserPassword = ""
    @State private var userErrorMessage = ""

    // Formular de adaugare a categoriilor
    @State private var newCategoryName = ""
    @State private var newCategoryType: CategoryType = .expense

    // Planificare buget
    @State private var calendarExpanded = false
    @State private var selectedPlanMonth = Date() 
    @State private var selectedExpenseCategory: CategoryEntity?
    @State private var budgetGoalTarget = ""
    @State private var showBudgetAlreadyExistsAlert = false
    
    // Fetch Requests
    @FetchRequest(entity: UserEntity.entity(), sortDescriptors: [])
    var coreDataUsers: FetchedResults<UserEntity>

    @FetchRequest(entity: CategoryEntity.entity(), sortDescriptors: [])
    var coreDataCategories: FetchedResults<CategoryEntity>

    @FetchRequest(
        entity: BudgetPlanEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \BudgetPlanEntity.date, ascending: false)]
    )
    var budgetPlans: FetchedResults<BudgetPlanEntity>
    
    var body: some View {
        ZStack {
            Color(.systemGray4).edgesIgnoringSafeArea(.all)

            List {
                // Utilizatori
                Section("Utilizatori") {
                    let adminName = budgetManager.currentUser?.username
                    let users = coreDataUsers.filter {
                        $0.role == "regular" &&
                        ($0.createdBy == adminName || $0.createdBy == nil)
                    }
                    if users.isEmpty {
                        Text("Nu ai adăugat niciun utilizator.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(users, id: \.id) { u in
                            HStack {
                                Text(u.username ?? "–")
                                Spacer()
                                Text("Regular").foregroundColor(.green)
                            }
                        }
                        .onDelete(perform: deleteUser)
                    }
                    Button("Adaugă Utilizator") { showAddUser = true }
                }

                // Categorii
                Section("Categorii") {
                    let adminName = budgetManager.currentUser?.username
                    let cats = coreDataCategories.filter {
                        $0.createdBy == adminName || $0.createdBy == nil
                    }
                    if cats.isEmpty {
                        Text("Nu există categorii.").foregroundColor(.gray)
                    } else {
                        ForEach(cats, id: \.id) { c in
                            Text("\(c.name ?? "–") (\(c.type == "expense" ? "Cheltuieli" : "Venituri"))")
                        }
                        .onDelete(perform: deleteCategory)
                    }
                    Button("Adaugă Categorie") { showAddCategory = true }
                }

                // Planificare Buget Lunar
                Section("Planificare Buget Lunar") {
                    Button("Planifică Buget") {
                        calendarExpanded = false
                        selectedPlanMonth = Date()
                        selectedExpenseCategory = nil
                        budgetGoalTarget = ""
                        showPlanBudget = true
                    }
                }

                // Rapoarte Lunare
                Section("Rapoarte Lunare") {
                    Button("Vezi Rapoarte") { showReports = true }
                    Button("Adaugă Raport Lunar") { showAddReport = true }
                }
            }
            .listStyle(GroupedListStyle())
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Panou Admin")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Înapoi") { presentationMode.wrappedValue.dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Mergi la Dashboard",
                               destination: DashboardView().environmentObject(budgetManager))
            }
        }

        // Formular de adăugare utilizator
        .sheet(isPresented: $showAddUser) {
            VStack {
                Text("Adaugă Utilizator").font(.headline)
                TextField("Nume utilizator", text: $newUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("Parolă", text: $newUserPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                if !userErrorMessage.isEmpty {
                    Text(userErrorMessage).foregroundColor(.red)
                }
                Button("Salvează") { addNewRegularUser() }
                    .padding()
                Spacer()
            }
            .padding()
        }

        // Formular de adăugare categorie
        .sheet(isPresented: $showAddCategory) {
            VStack {
                Text("Adaugă Categorie").font(.headline)
                TextField("Nume categorie", text: $newCategoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Picker("Tip", selection: $newCategoryType) {
                    Text("Cheltuieli").tag(CategoryType.expense)
                    Text("Venituri").tag(CategoryType.income)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                Button("Salvează") {
                    addNewCategory()
                    showAddCategory = false
                }
                .padding()
                Spacer()
            }
            .padding()
        }

        // Formular de planificare buget lunar
        .sheet(isPresented: $showPlanBudget) {
            let adminName = budgetManager.currentUser?.username
            let expenseCats = coreDataCategories.filter {
                $0.type == "expense" &&
                ($0.createdBy == adminName || $0.createdBy == nil)
            }
            let myPlans = budgetPlans.filter { $0.createdBy == adminName }

            VStack(alignment: .leading, spacing: 16) {
                Text("Planifică Buget Lunar")
                    .font(.headline)

                Menu {
                    ForEach(1..<13, id: \.self) { month in
                        Button(action: {
                            var components = Calendar.current.dateComponents([.year], from: Date())
                            components.month = month
                            selectedPlanMonth = Calendar.current.date(from: components) ?? Date()
        
                        }) {
                            Text(CoreDataUtils.monthName(for: month))
                        }
                    }
                } label: {
                    Text("Alege luna: \(CoreDataUtils.monthName(for: Calendar.current.component(.month, from:selectedPlanMonth)))")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }

                // Formular nou plan
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Categorie cheltuieli", selection: $selectedExpenseCategory) {
                        ForEach(expenseCats, id: \.id) { cat in
                            Text(cat.name ?? "–").tag(cat as CategoryEntity?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    TextField("Sumă totală", text: $budgetGoalTarget)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)

                    Button("Salvează Planul") {
                        guard let cat = selectedExpenseCategory else { return }
                        addBudgetPlan(for: cat)
                    }
                    .padding(.top)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                // Alertă dacă planul este depășit
                .alert("Atenționare", isPresented: $showBudgetAlreadyExistsAlert) {
                    Button("OK") {
                        presentationMode.wrappedValue.dismiss()
                    }
                } message: {
                    if let categoryName = selectedExpenseCategory?.name {
                        Text("Pentru categoria „\(categoryName)” este deja definită o planificare bugetară.")
                    } else {
                        Text("Este deja definită o planificare bugetară pentru categoria selectată.")
                    }
                }
                
                // Filtrăm planurile în funcție de luna selectată
                let filteredPlans = myPlans.filter { plan in
                    guard let date = plan.date else { return false }
                    let planMonth = Calendar.current.component(.month, from: date)
                    let selectedMonth = Calendar.current.component(.month, from: selectedPlanMonth)
                    return planMonth == selectedMonth
                }

                if !filteredPlans.isEmpty {
                    Text("Planuri existente:")
                        .font(.subheadline)
                        .padding(.bottom, 4)

                    // Lista pentru planuri
                    List {
                        Section(header:
                            HStack {
                                Text("Categorie").bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Stabilit").bold()
                                    .frame(width: 62, alignment: .center)
                                Text("Cheltuit").bold()
                                    .frame(width: 62, alignment: .center)
                                Text("Disponibil").bold()
                                    .frame(width: 71, alignment: .center)
                            }
                        ) {
                            ForEach(filteredPlans, id: \.id) { plan in
                                HStack {
                                    Text(plan.title ?? "")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(String(format: "%.2f", plan.amount))
                                        .frame(width: 62, alignment: .center)
                                    Text(String(format: "%.2f", plan.progress))
                                        .frame(width: 62, alignment: .center)
                                    let exceeded = plan.amount - plan.progress
                                    Text(String(format: "%.2f", exceeded))
                                    .frame(width: 71, alignment: .center)
                                    .foregroundColor(exceeded < 0 ? .red : .primary)
                                }
                            }
                            .onDelete { offsets in
                                deleteBudgetPlans(offsets: offsets, plans: myPlans)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: .infinity)
                }

                Spacer()
            }
            .padding()
        }

        .sheet(isPresented: $showReports) {
            ReportsView().environmentObject(budgetManager)
        }

        .sheet(isPresented: $showAddReport) {
            MonthlyReportView().environment(\.managedObjectContext, viewContext)
        }
    }

    private func addNewRegularUser() {
        guard !newUserName.isEmpty, !newUserPassword.isEmpty else {
            userErrorMessage = "Toate câmpurile sunt obligatorii."
            return
        }
        guard newUserPassword.count >= 8 else {
            userErrorMessage = "Parola trebuie să aibă minim 8 caractere."
            return
        }
        if coreDataUsers.contains(where: { $0.username?.lowercased() == newUserName.lowercased() }) {
            userErrorMessage = "Utilizator deja existent."
            return
        }
        let u = UserEntity(context: viewContext)
        u.id = UUID()
        u.username = newUserName
        u.password = newUserPassword
        u.role = "regular"
        u.createdBy = budgetManager.currentUser?.username
        try? viewContext.save()
        userErrorMessage = ""
        showAddUser = false
    }

    private func deleteUser(at offsets: IndexSet) {
        offsets.forEach { viewContext.delete(coreDataUsers[$0]) }
        try? viewContext.save()
    }

    private func addNewCategory() {
        let c = CategoryEntity(context: viewContext)
        c.id = UUID()
        c.name = newCategoryName
        c.type = newCategoryType == .expense ? "expense" : "income"
        c.createdBy = budgetManager.currentUser?.username
        try? viewContext.save()
    }

    private func deleteCategory(at offsets: IndexSet) {
        let adminName = budgetManager.currentUser?.username
        let cats = coreDataCategories.filter {
            $0.createdBy == adminName || $0.createdBy == nil
        }
        offsets.forEach { index in
            viewContext.delete(cats[index])
        }
        try? viewContext.save()
    }

    private func deleteBudgetPlans(offsets: IndexSet, plans: [BudgetPlanEntity]) {
        for idx in offsets {
            viewContext.delete(plans[idx])
        }
        try? viewContext.save()
    }

    private func addBudgetPlan(for cat: CategoryEntity) {

        let adminName = budgetManager.currentUser?.username
        let myPlans = budgetPlans.filter { $0.createdBy == adminName }
        let filteredPlans = myPlans.filter { plan in
            guard let date = plan.date else { return false }
            let planMonth = Calendar.current.component(.month, from: date)
            let selectedMonth = Calendar.current.component(.month, from: selectedPlanMonth)
            return planMonth == selectedMonth
        }

        // Verifica daca exista deja un plan pentru categoria selectata
        if filteredPlans.contains(where: { $0.title == cat.name && Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedPlanMonth) }) {
            showBudgetAlreadyExistsAlert = true
            return
        }

        // Definim fetchRequest-ul pentru tranzacții
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", cat)

        do {
        let transactions = try viewContext.fetch(fetchRequest)
        let totalAmountSum = transactions.reduce(0.0) { $0 + $1.totalAmount }
        print("Suma totală a tranzacțiilor pentru categoria \(cat.name ?? "necunoscută"): \(totalAmountSum)")
        
        let bp = BudgetPlanEntity(context: viewContext)
        bp.id = UUID()
        bp.title = cat.name
        bp.amount = Double(budgetGoalTarget) ?? 0
        bp.progress = totalAmountSum 
        bp.date = selectedPlanMonth
        bp.createdBy = budgetManager.currentUser?.username
        bp.familyID = budgetManager.currentUser?.familyID
        
        try viewContext.save()
    } catch {
        print("⚠️ Eroare la obținerea tranzacțiilor sau salvarea planului: \(error)")
    }
    }
}

struct AdminPanelView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminPanelView()
                .environmentObject(BudgetManager())
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
