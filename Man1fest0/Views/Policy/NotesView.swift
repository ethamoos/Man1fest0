//
//  NotesView.swift
//  Man1fest0
//
//  Created by Amos Deane on 14/07/2025.
//
import SwiftUI

struct NoteView: View {
    let note: Note
    var body: some View {
        HStack {
            Text(note.mainBody ?? "-")
            Text(note.reference ?? "-")
            Spacer()
            Text(note.additionalNotes ?? "-")
        }
    }
}

struct NotesView: View {
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Note.reference, ascending: true),
            NSSortDescriptor(keyPath: \Note.mainBody, ascending: true),
        ]
    )
    
    var notes: FetchedResults<Note>
    @State private var isAddContactPresented = false
    @EnvironmentObject var coreDataStack: CoreDataStack
    
    var body: some View {
//        NavigationView {
        HStack {
            List(notes, id: \.self) {
                NoteView(note: $0)
            }
            .listStyle(.plain)
            //            .navigationBarTitle("Notes", displayMode: .inline)
            //            .navigationBarItems(trailing:
            Button {
                isAddContactPresented.toggle()
            } label: {
                Image(systemName: "plus")
                    .sheet(isPresented: $isAddContactPresented) {
                        AddNewContact(isAddContactPresented: $isAddContactPresented)
                            .environmentObject(coreDataStack)
                    }
            }
        }
        .frame(minWidth: 400, alignment: .leading)

    }
}
    
struct AddNewContact: View {
    
    @EnvironmentObject var coreDataStack: CoreDataStack
    @Binding var isAddContactPresented: Bool
    @State var mainBody = ""
    @State var reference = ""
    @State var additionalNotes = ""
    
    var body: some View {
//        NavigationView {
            VStack(spacing: 16) {
                Text("Add Note:").bold()
                TextField("Main Body", text: $mainBody)
                TextField("Reference", text: $reference)
                TextField("Additional Notes", text: $additionalNotes)
                //                    .keyboardType(.phonePad)
                Spacer()
            }
            .padding(16)
//            .navigationTitle("Add A New Note")
//            .navigationBarItems(trailing:
            .toolbar{
            Button(action: saveNote) {
                Image(systemName: "checkmark")
                    .font(.headline)
            }
            .disabled(isDisabled)
        }
    }
        
    var isDisabled: Bool {
//        mainBody.isEmpty || reference.isEmpty || additionalNotes.isEmpty
        mainBody.isEmpty
    }
    
    func saveNote() {
        print("Saving note")
        coreDataStack.insertNote(mainBody: mainBody,reference: reference, additionalNotes: additionalNotes)
        isAddContactPresented.toggle()
    }
}
//}
        //struct ContentView_Previews: PreviewProvider {
        //    static var previews: some View {
        //        ContentView()
        //    }
        //}
