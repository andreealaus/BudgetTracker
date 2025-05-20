import SwiftUI

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    // Variabile locale pentru formular
    @State private var newCategoryName: String = ""
    @State private var newCategoryType: CategoryType = .expense

    var body: some View {
        VStack(spacing: 20) {
            Text("Adaugă Categorie")
                .font(.largeTitle)
            
            TextField("Nume Categorie", text: $newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Picker("Tip", selection: $newCategoryType) {
                Text("Cheltuieli").tag(CategoryType.expense)
                Text("Venituri").tag(CategoryType.income)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Button("Salvează") {
                // Aici vei adăuga logica de salvare a categoriei
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.orange)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

struct AddCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddCategoryView()
    }
}
