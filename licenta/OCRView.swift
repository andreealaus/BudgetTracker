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
                            }
                        }
                    }
                }
            }
            .alert("Alege o categorie", isPresented: $showCategoryAlert) {
                    Button("OK", role: .cancel) { }
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
            let addTransactionView = AddTransactionView()
            addTransactionView.updateBudgetPlan(for: selectedCategory, addedAmount: amount, planOwner: planOwner, context: viewContext)
        }
    }
}

struct OCRView_Previews: PreviewProvider {
    static var previews: some View {
        OCRView().environmentObject(BudgetManager())
    }
}
