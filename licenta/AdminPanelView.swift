import SwiftUI
import CoreData

struct AdminPanelView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // MARK: – Sheet flags
    @State private var showAddUser = false
    @State private var showAddCategory = false
    @State private var showPlanBudget = false
    @State private var showReports = false
    @State private var showAddReport = false

    // MARK: – Add User form
    @State private var newUserName = ""
    @State private var newUserPassword = ""
    @State private var userErrorMessage = ""

    // MARK: – Add Category form
    @State private var newCategoryName = ""
    @State private var newCategoryType: CategoryType = .expense

    // MARK: – Plan Budget form
    @State private var calendarExpanded = false
    @State private var selectedPlanMonth = Date() 
    @State private var selectedExpenseCategory: CategoryEntity?
    @State private var budgetGoalTarget = ""
    @State private var budgetGoalProgress = ""
    //obtinerea numelui lunii
    private func monthName(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        return dateFormatter.monthSymbols[month - 1]
    }
    
    // MARK: – CoreData fetches
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
                // MARK: – Utilizatori
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

                // MARK: – Categorii
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

                // MARK: – Planificare Buget Lunar
                Section("Planificare Buget Lunar") {
                    Button("Planifică Buget") {
                        calendarExpanded = false
                        selectedPlanMonth = Date()
                        selectedExpenseCategory = nil
                        budgetGoalTarget = ""
                        budgetGoalProgress = ""
                        showPlanBudget = true
                    }
                }

                // MARK: – Rapoarte Lunare
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

        // MARK: – Add User Sheet
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

        // MARK: – Add Category Sheet
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

        // MARK: – Planifică Buget Sheet
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
                            Text(monthName(for: month))
                        }
                    }
                } label: {
                    Text("Alege luna: \(monthName(for: Calendar.current.component(.month, from:selectedPlanMonth)))")
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
                        showPlanBudget = false
                    }
                    .padding(.top)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                
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

                    // Lista cu swipe-to-delete pentru planuri
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
                                    Text(exceeded > 0
                                        ? String(format: "%.2f", exceeded)
                                        : "0.00"
                                    )
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

        // MARK: – View Reports Sheet
        .sheet(isPresented: $showReports) {
            ReportsView().environmentObject(budgetManager)
        }

        // MARK: – Add Monthly Report Sheet
        .sheet(isPresented: $showAddReport) {
            MonthlyReportView().environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: – Helper Methods

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
        let bp = BudgetPlanEntity(context: viewContext)
        bp.id = UUID()
        bp.title = cat.name
        bp.amount = Double(budgetGoalTarget) ?? 0
        bp.progress = Double(budgetGoalProgress) ?? 0
        bp.date = selectedPlanMonth
        bp.createdBy = budgetManager.currentUser?.username
        bp.familyID = budgetManager.currentUser?.familyID
        try? viewContext.save()
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
