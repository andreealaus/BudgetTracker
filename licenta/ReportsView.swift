import SwiftUI
import CoreData

struct ReportsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var budgetManager: BudgetManager
    @FetchRequest(
        entity: ReportEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ReportEntity.date, ascending: false)]
    )
    var reports: FetchedResults<ReportEntity>
    var filteredReports: [ReportEntity] {
        reports.filter { $0.createdBy == budgetManager.currentUser?.username }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredReports, id: \.id) { report in
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
            let reportToDelete = filteredReports[index]
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
            
            let numbers = extractNumbers(from: report.content ?? "")
            let data = numbers.count > 1 ? Array(numbers.dropFirst()) : []
            let colors = generateColors(count: data.count)
            let usersExtracted = extractUsernames(from: report.content ?? "")
            let users = usersExtracted.count > 1 ? Array(usersExtracted.dropFirst()) : []
            
            PieChartView(
                data: data,
                colors: colors
            )
            .frame(height: 200)
            .frame(maxWidth: .infinity, alignment: .center) 
            .padding(.horizontal)
            
            // Legenda
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Venituri: \(String(format: "%.2f", numbers[0])) lei")
                        .font(.subheadline)
                }
                ForEach(0..<data.count, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(colors[index])
                            .frame(width: 15, height: 15)
                        Text("\(users[index]): \(String(format: "%.2f", data[index])) lei")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.top)
            
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
    
    private func extractNumbers(from text: String) -> [Double] {
        let pattern = "(\\d+(\\.\\d+)?)\\s*lei"
        let regex = try? NSRegularExpression(pattern: pattern)
        
        guard let regex = regex else {
            print("Failed to create regex")
            return []
        }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
        
        return matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: text) { 
                return Double(text[range])
            }
            return nil
        }
    }

    private func generateColors(count: Int) -> [Color] {
        let baseColors: [Color] = [.blue, .orange, .green, .pink, .purple, .yellow, .red, .cyan, .teal, .indigo, .mint, .brown, .gray]
        let shuffledColors = baseColors.shuffled()
        var colors: [Color] = []
        
        for i in 0..<count {
            colors.append(shuffledColors[i % shuffledColors.count]) 
        }
        
        return colors
    }
    
    private func extractUsernames(from text: String) -> [String] {
        let pattern = "(?:Cheltuieli:\\s*)?(\\w+):"
        let regex = try? NSRegularExpression(pattern: pattern)
        
        guard let regex = regex else {
            print("Failed to create regex")
            return []
        }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
        
        return matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: text) { 
                return String(text[range])
            }
            return nil
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
