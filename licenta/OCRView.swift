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
                            let familyAdmin = fetchCurrentUserEntity()?.createdBy
                            
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
                // Simulăm extragerea sumei din imaginea aleasă
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
        // Creăm un nou TransactionEntity pentru cheltuieli
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
    }

    private func fetchCurrentUserEntity() -> UserEntity? {
        guard let username = budgetManager.currentUser?.username else { return nil }
        let req: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        req.predicate = NSPredicate(format: "username == %@", username)
        return (try? viewContext.fetch(req))?.first
    }
}

struct OCRView_Previews: PreviewProvider {
    static var previews: some View {
        OCRView().environmentObject(BudgetManager())
    }
}
