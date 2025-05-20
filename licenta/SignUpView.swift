import SwiftUI
import CoreData

struct RegistrationView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Înregistrare Admin")
                .font(.largeTitle)
                .bold()
            
            TextField("Username", text: $username)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("Parolă", text: $password)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .textContentType(.oneTimeCode)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("Confirmă Parola", text: $confirmPassword)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .textContentType(.oneTimeCode)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil) 
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button(action: {
                registerAdminUser()
            }) {
                Text("Înregistrează-te")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Înregistrare Admin")
    }
    
    private func registerAdminUser() {
        // Validare câmpuri
        guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Toate câmpurile sunt obligatorii."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Parolele nu se potrivesc."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Parola trebuie să aibă cel puțin 8 caractere."
            return
        }
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$"
        guard NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password) else {
            errorMessage = "Parola trebuie să conțină minim 8 caractere, o literă mare, o literă mică, un număr și un caracter special."
            return
        }
        
        // Verificăm dacă există deja un utilizator cu același username (case-insensitive)
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username ==[c] %@", username)
        do {
            let count = try viewContext.count(for: fetchRequest)
            if count > 0 {
                errorMessage = "Un utilizator cu acest nume există deja."
                return
            }
        } catch {
            errorMessage = "Eroare la verificarea utilizatorilor: \(error.localizedDescription)"
            return
        }
        
        // Creează noul UserEntity cu role "admin"
        let newUserEntity = UserEntity(context: viewContext)
        newUserEntity.id = UUID()
        newUserEntity.username = username
        newUserEntity.password = password
        newUserEntity.role = "admin"
        
        do {
            try viewContext.save()
            print("Utilizator admin salvat: \(username)")
            // Actualizează currentUser în BudgetManager (poți folosi modelul simplu User)
            budgetManager.currentUser = User(username: username, role: .admin)
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = "Eroare la salvare: \(error.localizedDescription)"
            print("Eroare la salvarea utilizatorului: \(error)")
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegistrationView()
                .environmentObject(BudgetManager())
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
