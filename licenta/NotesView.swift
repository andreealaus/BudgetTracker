import SwiftUI
import CoreData

struct NotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: NoteEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.date, ascending: false)]
    )
    var allNotes: FetchedResults<NoteEntity>
    
    // Variabila care controlează modul de selecție
    @State private var isSelecting: Bool = false
    // Set de ID-uri (UUID) ale notițelor selectate
    @State private var selectedNotes: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Când nu e în modul de selecție, afișăm butonul "Elimină notiță"
                if !isSelecting {
                    Button("Elimină notiță") {
                        isSelecting = true
                    }
                    .padding()
                }
                
                // Lista notițelor cu selecție multiplă
                List(allNotes, id: \.id, selection: $selectedNotes) { note in
                    rowView(note: note)
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, .constant(isSelecting ? EditMode.active : EditMode.inactive))
            }
            .navigationTitle("Notițe")
            .toolbar {
                // Dacă suntem în modul de selecție, adăugăm butoanele "Șterge selecția" și "Cancel" în bara de navigare
                if isSelecting {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Șterge selecția") {
                            deleteSelectedNotes()
                            isSelecting = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            isSelecting = false
                            selectedNotes.removeAll()
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func rowView(note: NoteEntity) -> some View {
        // Obținem id-ul notei (dacă lipsește, folosim un UUID placeholder)
        let noteID = note.id ?? UUID()
        let isSelected = selectedNotes.contains(noteID)
        
        HStack {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            VStack(alignment: .leading) {
                Text(note.content ?? "")
                    .font(.body)
                if let date = note.date {
                    // Afișează data în formatul: Data: 22 Feb 2025 la 20:45
                    Text("Data: \(dateFormatter.string(from: date))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .contentShape(Rectangle()) // Asigură că întregul rând este sensibil la tap
        .onTapGesture {
            if isSelecting {
                toggleSelection(for: note)
            }
        }
    }
    
    private func toggleSelection(for note: NoteEntity) {
        guard let id = note.id else { return }
        if selectedNotes.contains(id) {
            selectedNotes.remove(id)
        } else {
            selectedNotes.insert(id)
        }
    }
    
    private func deleteSelectedNotes() {
        for note in allNotes {
            if let id = note.id, selectedNotes.contains(id) {
                viewContext.delete(note)
            }
        }
        do {
            try viewContext.save()
        } catch {
            print("Eroare la ștergerea notelor selectate: \(error)")
        }
        selectedNotes.removeAll()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ro_RO")
        formatter.dateFormat = "dd MMM yyyy 'la' HH:mm"
        return formatter
    }
}

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
