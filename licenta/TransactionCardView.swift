import SwiftUI

struct TransactionCardView: View {
    var transaction: TransactionEntity
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'la' HH:mm"
        formatter.locale = Locale(identifier: "ro_RO")
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Utilizator: \(transaction.user?.username ?? "Unknown")")
                .font(.headline)
            Text("Sumă: \(transaction.totalAmount, specifier: "%.2f")")
                .font(.subheadline)
            if let date = transaction.date {
                Text("Data: \(date, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if let note = transaction.note, !note.isEmpty {
                Text("Note: \(note)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        .shadow(radius: 2)
        .padding(.vertical, 5)
    }
}

struct TransactionCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Pentru preview, poți crea un obiect dummy TransactionEntity
        // Aici folosim un preview placeholder, dar în proiectul real, TransactionEntity vine din Core Data.
        let dummyTransaction = TransactionEntity(context: PersistenceController.shared.container.viewContext)
        dummyTransaction.id = UUID()
        dummyTransaction.totalAmount = 123.45
        dummyTransaction.note = "Exemplu notiță"
        // Asigură-te că dummyTransaction.user și dummyTransaction.date sunt setate dacă dorești.
        
        return TransactionCardView(transaction: dummyTransaction)
            .previewLayout(.sizeThatFits)
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
