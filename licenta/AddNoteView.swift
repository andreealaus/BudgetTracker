import SwiftUI
import CoreData

struct AddNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var noteContent: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Adaugă Notiță")
                    .font(.largeTitle)
                    .padding()
                
                TextEditor(text: $noteContent)
                    .border(Color.gray, width: 1)
                    .padding()
                
                Button("Salvează") {
                    let newNote = NoteEntity(context: viewContext)
                    newNote.id = UUID()
                    newNote.content = noteContent
                    newNote.date = Date()
                    
                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Eroare la salvarea notiței: \(error)")
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Adaugă Notiță")
        }
        .preferredColorScheme(.dark)
    }
}
