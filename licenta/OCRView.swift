import SwiftUI
import CoreData

struct OCRView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedImage: UIImage?
    @State private var extractedAmount: Double?
    @State private var showingImagePicker = false
    @State private var selectedCategory: CategoryEntity?
    @State private var categoryPickerPresented = false
    // Pentru alertă când nu există categorie
    @State private var showCategoryAlert = false
    @State private var showBudgetExceededAlert = false
    @State private var showPhotoAlert = false
    @State private var showNoPhotoAlert = false

    // Categoriile din Core Data
    @FetchRequest(
        entity: CategoryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)]
    ) var coreDataCategories: FetchedResults<CategoryEntity>

    var body: some View {
        VStack(spacing: 20) {
            // Imaginea selectată
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
            } else {
                Text("Selectează bonul din galerie")
                    .foregroundColor(.gray)
            }

            // Afișăm suma extrasă
            if let amount = extractedAmount {
                Text("Suma extrasă: \(amount, specifier: "%.2f")")
                    .font(.title2)
                    .foregroundColor(.green)
            }

            // Picker pentru selectarea categoriei
            Section(header: Text("Alege Categoria")) {
                Picker("Categorie", selection: $selectedCategory) {
                    ForEach(
                        coreDataCategories.filter { category in
                            // username-ul curent
                            let currentUser = budgetManager.currentUser?.username
                            // adminul familiei (dacă există)
                            let familyAdmin = CoreDataUtils.fetchCurrentUserEntity(context: viewContext, username: budgetManager.currentUser?.username)?.createdBy
                            
                            // Afișăm categoriile implicite sau cele adăugate de adminul din familia utilizatorului
                            return category.createdBy == nil
                                || category.createdBy == currentUser
                                || category.createdBy == familyAdmin
                        },
                        id: \.id
                    ) { category in
                        Text(category.name ?? "Necunoscut")
                            .tag(Optional(category))
                    }
                }
                .pickerStyle(MenuPickerStyle()) // Sau alt stil dorit
            }

            // Butonul pentru alegerea imaginii
            Button("Alege imaginea din galerie") {
                showingImagePicker = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Extrage suma") {
                guard let imageToProcess = selectedImage else {
                    print("Nu există o imagine pentru procesare")
                    showNoPhotoAlert = true
                    return
                }

                if selectedCategory == nil {
                        showCategoryAlert = true
                } else {
                    OCRService.scanReceipt(from: imageToProcess) { result in
                        DispatchQueue.main.async {
                            extractedAmount = result
                            if let amount = result {
                                // Adăugăm tranzacția de cheltuieli automat
                                addExpenseTransaction(amount: amount)
                            } else {
                                print("Nu a fost extrasă nicio sumă")
                                showPhotoAlert = true
                            }
                        }
                    }
                }
            }
            .alert("Alege o categorie", isPresented: $showCategoryAlert) {
                    Button("OK", role: .cancel) { }
            }
            // Alertă dacă planul este depășit
            .alert("Atentionare Buget", isPresented: $showBudgetExceededAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Bugetul pentru categoria selectată fost depășit.")
            }
            // Alertă dacă poza nu contine suma
            .alert("Atentionare Poza", isPresented: $showPhotoAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Fotografia selectata nu a fost recunoscuta drept bon fiscal.")
            }// Alertă dacă nu a fost selectata poza
            .alert("Atentionare Poza", isPresented: $showNoPhotoAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Selecteaza o fotografie.")
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
    }

    private func addExpenseTransaction(amount: Double) {
        // Nou TransactionEntity pentru cheltuieli
        let newTx = TransactionEntity(context: viewContext)
        newTx.id = UUID()
        newTx.date = Date()
        newTx.totalAmount = amount
        newTx.note = "Bon extras prin OCR"

        // Setăm categoria selectată
        if let selectedCategory = selectedCategory {
            newTx.category = selectedCategory
        } else {
            print("Nu s-a selectat o categorie pentru tranzacție.")
        }

        // Setăm userul curent, dacă este disponibil
        if let currentUser = budgetManager.currentUser {
            let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchReq.predicate = NSPredicate(format: "username == %@", currentUser.username)
            if let foundUser = try? viewContext.fetch(fetchReq).first {
                newTx.user = foundUser
            } else {
                print("Nu am găsit userEntity pentru \(currentUser.username).")
            }
        }

        do {
            try viewContext.save()
            print("Tranzacție de cheltuieli adăugată automat prin OCR.")
        } catch {
            print("Eroare la salvarea tranzacției: \(error)")
        }
        
        // Actualizăm planul de buget asociat categoriei
        let planOwner: String
        if let userEntity = (selectedCategory == nil ? nil : CoreDataUtils.fetchCurrentUserEntity(context: viewContext, username: budgetManager.currentUser?.username)),
           let createdBy = userEntity.createdBy {
            planOwner = createdBy
        } else {
            planOwner = budgetManager.currentUser?.username ?? ""
        }
        if let selectedCategory = selectedCategory {
            updateBudgetPlan(for: selectedCategory, addedAmount: amount, planOwner: planOwner, context: viewContext)
        }
    }

    private func updateBudgetPlan(for category: CategoryEntity, addedAmount: Double, planOwner: String, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? Date()

        let planReq: NSFetchRequest<BudgetPlanEntity> = BudgetPlanEntity.fetchRequest()
        planReq.predicate = NSPredicate(format: "title == %@ AND createdBy == %@ AND date >= %@ AND date < %@", category.name ?? "", planOwner, startOfMonth as NSDate, endOfMonth as NSDate)

        do {
            if let plan = try context.fetch(planReq).first {
                plan.progress += addedAmount
                let exceeded = plan.progress > plan.amount
                try context.save()
                if exceeded {
                    showBudgetExceededAlert = true // Update the alert state
                }
            }
        } catch {
            print("⚠️ Eroare la actualizarea planului: \(error)")
        }
    }
}

struct OCRView_Previews: PreviewProvider {
    static var previews: some View {
        OCRView().environmentObject(BudgetManager())
    }
}
