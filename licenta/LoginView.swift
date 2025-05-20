import SwiftUI
import CoreData

struct LoginView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingRegistration = false
    @State private var username: String = ""
    @State private var password: String = ""
    
    // Controlăm navigarea condiționată
    @State private var canNavigate: Bool = false
    
    // Pentru afișarea alertelor
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fundal gri deschis
                Color(.systemGray4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Login")
                        .font(.largeTitle)
                        .padding()
                    
                NavigationLink(
                    destination:RegistrationView().environmentObject(budgetManager),
                    isActive: $showingRegistration
                                    ) {
                                        EmptyView()
                                    }
                    
                    Button("Înregistrează-te") {
                        showingRegistration = true
                    }
                    .padding()
                    .foregroundColor(.blue)
                    
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    SecureField("Parola", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Navigăm către HomeView doar dacă validarea reușește
                    NavigationLink(destination: HomeView(), isActive: $canNavigate) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        loginAction()
                    }) {
                        Text("Log In")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Eroare la login"),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("OK")))
                }
            }
            // Dacă vrei text alb pe fundal gri, menține dark mode:
            .preferredColorScheme(.dark)
        }
    }
    
    private func loginAction() {
        // Verificăm dacă câmpurile sunt goale
        if username.isEmpty || password.isEmpty {
            alertMessage = "Introduceți un username și o parolă."
            showAlert = true
            return
        }
        
        // Căutăm userul în Core Data
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let userEntity = results.first {
                // Avem un user cu acest username
                if userEntity.password == password {
                    // Parola corectă
                    let role: UserRole = (userEntity.role == "admin") ? .admin : .regular
                    let user = User(username: userEntity.username ?? "", role: role)
                    budgetManager.currentUser = user
                    canNavigate = true
                } else {
                    alertMessage = "Parolă incorectă."
                    showAlert = true
                }
            } else {
                alertMessage = "Username inexistent în baza de date."
                showAlert = true
            }
        } catch {
            print("Eroare la fetch: \(error)")
            alertMessage = "Eroare internă la login."
            showAlert = true
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
