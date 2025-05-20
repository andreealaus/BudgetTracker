import SwiftUI
import CoreData

struct MonthlyReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedMonth: Date = Date()
    @State private var reportContent: String = ""
    @State private var showSuccessMessage: Bool = false

    var body: some View {
        VStack {
            // Selectarea lunii
            DatePicker("Selectează Luna", selection: $selectedMonth, displayedComponents: .date)
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
            
            // Afișarea raportului pentru luna selectată
            Text("Raport pentru luna \(getMonthString())")
                .font(.headline)
                .padding()

            // Afișarea conținutului raportului
            Text(reportContent)
                .padding()

            // Butonul de salvare raport
            Button("Salvează Raport") {
                saveReport()
            }
            .padding()
            .foregroundColor(.blue)
            .alert(isPresented: $showSuccessMessage) {
                Alert(title: Text("Raport Salvat"),
                      message: Text("Raportul lunar pentru \(getMonthString()) a fost salvat cu succes."),
                      dismissButton: .default(Text("OK")))
            }
        }
        .onChange(of: selectedMonth) { newValue in
            generateReport(for: newValue)
        }
        .navigationTitle("Adaugă Raport Lunar")
    }

    // Generarea raportului pentru luna selectată, cu mesaje de debug
    private func generateReport(for month: Date) {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            print("Nu s-a putut calcula startul lunii pentru \(month)")
            return
        }
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            print("Nu s-a putut calcula sfârșitul lunii pentru \(startOfMonth)")
            return
        }
        
        // Formatter pentru debug
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        
        print("StartOfMonth: \(formatter.string(from: startOfMonth))")
        print("EndOfMonth: \(formatter.string(from: endOfMonth))")
        
        // Definim fetchRequest-ul pentru tranzacții
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfMonth as NSDate, endOfMonth as NSDate)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            print("Fetched \(results.count) transactions for month \(getMonthString())")
            for tx in results {
                if let txDate = tx.date {
                    print("Transaction date: \(formatter.string(from: txDate))")
                }
            }
            
            let income = results.filter { $0.category?.type == "income" }
                                 .reduce(0) { $0 + $1.totalAmount }
            let expense = results.filter { $0.category?.type == "expense" }
                                  .reduce(0) { $0 + $1.totalAmount }
            
            reportContent = """
                Venituri: \(String(format: "%.2f", income))
                Cheltuieli: \(String(format: "%.2f", expense))
                Net: \(String(format: "%.2f", income - expense))
            """
        } catch {
            print("Eroare la generarea raportului: \(error)")
        }
    }
    
    // Salvarea raportului în Core Data
    private func saveReport() {
        let newReport = ReportEntity(context: viewContext)
        newReport.id = UUID()
        newReport.title = "Raport pentru luna \(getMonthString())"
        newReport.content = reportContent
        newReport.date = selectedMonth
        
        do {
            try viewContext.save()
            showSuccessMessage = true
        } catch {
            print("Eroare la salvarea raportului: \(error)")
        }
    }

    // Funcție de obținere a lunii în format string
    private func getMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
}

struct MonthlyReportView_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyReportView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}

