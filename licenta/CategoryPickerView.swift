import SwiftUI
import CoreData

struct CategoryPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedCategory: CategoryEntity?
    
    // Folosim un @State pentru a salva ID-ul utilizatorului curent
    @State private var currentUserID: String = ""
    
    // FetchRequest pentru a aduce doar categoriile create de utilizatorul curent sau cele implicite
    @FetchRequest var categories: FetchedResults<CategoryEntity>
    
    init(selectedCategory: Binding<CategoryEntity?>) {
        self._selectedCategory = selectedCategory
        
        // Filtrăm categoriile pe baza ID-ului utilizatorului curent și al categoriilor implicite
        let currentUserID = UserDefaults.standard.string(forKey: "currentUserID") ?? ""
        
        // Initializăm FetchRequest cu un predicate dinamic
        self._categories = FetchRequest(
            entity: CategoryEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)],
            predicate: NSPredicate(format: "createdBy == %@ OR isDefault == %@", currentUserID, NSNumber(value: true))
        )
    }

    var body: some View {
        NavigationView {
            List(categories, id: \.id) { category in
                Text(category.name ?? "Necunoscut")
                    .onTapGesture {
                        selectedCategory = category
                        // Închidem pickerul după ce alegem o categorie
                    }
            }
            .navigationTitle("Selectează Categoria")
        }
    }
}
