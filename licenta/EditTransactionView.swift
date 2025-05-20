import SwiftUI
import CoreData

struct EditTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var transaction: TransactionEntity // Binding pentru tranzacția care se editează
    
    @State private var amount: Double
    @State private var note: String
    @State private var selectedCategory: CategoryEntity?
    
    // Variabile pentru selecția categoriei
    @FetchRequest(entity: CategoryEntity.entity(), sortDescriptors: [])
    var categories: FetchedResults<CategoryEntity>
    
    init(transaction: State<TransactionEntity>) {
        _transaction = transaction
        _amount = State(initialValue: transaction.wrappedValue.totalAmount)
        _note = State(initialValue: transaction.wrappedValue.note ?? "")
        _selectedCategory = State(initialValue: transaction.wrappedValue.category)
    }

    var body: some View {
        VStack {
            Text("Editează Tranzacția")
                .font(.headline)
                .padding()

            // Selector pentru sumă
            TextField("Sumă", value: $amount, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Selector pentru note
            TextField("Note", text: $note)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Selector pentru categorie
            Picker("Categorie", selection: $selectedCategory) {
                ForEach(categories, id: \.id) { category in
                    Text(category.name ?? "Necunoscut").tag(category as CategoryEntity?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            // Buton pentru a salva modificările
            Button("Salvează") {
                saveTransaction()
            }
            .padding()
        }
        .padding()
    }

    // Funcție pentru a salva modificările
    private func saveTransaction() {
        transaction.totalAmount = amount
        transaction.note = note
        transaction.category = selectedCategory
        
        do {
            try viewContext.save() // Salvează tranzacția modificată în Core Data
            print("Tranzacție salvată")
        } catch {
            print("Eroare la salvarea tranzacției: \(error)")
        }
    }
}
