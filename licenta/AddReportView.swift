import SwiftUI
import CoreData

struct AddReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMonth: Date = Date()
    @State private var reportTitle: String = ""
    @State private var reportContent: String = ""
    
    @FetchRequest(entity: TransactionEntity.entity(), sortDescriptors: [])
    var allTransactions: FetchedResults<TransactionEntity>
    
    var body: some View {
        VStack {
            Text("Adaugă Raport Lunar")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            // Selectare lună
            DatePicker("Selectează Luna", selection: $selectedMonth, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            
            // Titlu raport
            TextField("Titlu raport", text: $reportTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Conținut raport
            TextEditor(text: $reportContent)
                .frame(height: 150)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            // Buton de salvare
            Button("Salvează Raport") {
                saveReport()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
            
            // Afișare raport veniturilor și cheltuielilor
            let monthlyTransactions = allTransactions.filter { tx in
                if let date = tx.date {
                    return Calendar.current.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                }
                return false
            }
            
            let income = monthlyTransactions.filter { $0.category?.type == "income" }.reduce(0) { $0 + $1.totalAmount }
            let expense = monthlyTransactions.filter { $0.category?.type == "expense" }.reduce(0) { $0 + $1.totalAmount }
            
            Text("Venituri: \(income, specifier: "%.2f")")
                .foregroundColor(.green)
                .padding(.top)
            
            Text("Cheltuieli: \(expense, specifier: "%.2f")")
                .foregroundColor(.red)
                .padding(.top)
            
            Text("Net: \(income - expense, specifier: "%.2f")")
                .foregroundColor(.white)
                .padding(.top)
        }
        .padding()
        .background(Color(.systemGray5).edgesIgnoringSafeArea(.all))
    }
    
    private func saveReport() {
        guard !reportTitle.isEmpty else {
            print("Titlul raportului este obligatoriu.")
            return
        }
        
        let newReport = ReportEntity(context: viewContext)
        newReport.id = UUID()
        newReport.title = reportTitle
        newReport.content = reportContent
        newReport.date = selectedMonth
        
        do {
            try viewContext.save()
            print("Raport lunar salvat.")
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Eroare la salvarea raportului: \(error)")
        }
    }
}

struct AddReportView_Previews: PreviewProvider {
    static var previews: some View {
        AddReportView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}


