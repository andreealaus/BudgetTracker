import SwiftUI
import CoreData

struct ReportsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ReportEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ReportEntity.date, ascending: false)]
    )
    var reports: FetchedResults<ReportEntity>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(reports, id: \.id) { report in
                    NavigationLink(destination: ReportDetailView(report: report)) {
                        VStack(alignment: .leading) {
                            Text(report.title ?? "Fără titlu")
                                .font(.headline)
                            Text("Data: \(report.date ?? Date(), formatter: dateFormatter)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(report.content ?? "")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteReports)
            }
            .navigationTitle("Rapoarte Lunare")
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func deleteReports(at offsets: IndexSet) {
        for index in offsets {
            let reportToDelete = reports[index]
            viewContext.delete(reportToDelete)
        }
        do {
            try viewContext.save()
        } catch {
            print("Eroare la ștergerea raportului: \(error)")
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct ReportDetailView: View {
    let report: ReportEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(report.title ?? "Fără titlu")
                .font(.largeTitle)
                .padding(.bottom, 10)
            
            Text("Data: \(report.date ?? Date(), formatter: dateFormatter)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Divider()
            
            Text(report.content ?? "Fără conținut")
                .font(.body)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Detalii Raport")
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
