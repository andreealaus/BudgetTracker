import SwiftUI

struct AddUserView: View {
    @Environment(\.presentationMode) var presentationMode
    // Variabile locale pentru formular
    @State private var newUserName: String = ""
    @State private var newUserPassword: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Adaugă Utilizator")
                .font(.largeTitle)
            
            TextField("Nume Utilizator", text: $newUserName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            SecureField("Parolă", text: $newUserPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Salvează") {
                // Aici vei adăuga logica de salvare a utilizatorului
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

struct AddUserView_Previews: PreviewProvider {
    static var previews: some View {
        AddUserView()
    }
}
