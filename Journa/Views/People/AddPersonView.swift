import SwiftUI

struct AddPersonView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var note = ""
    
    var body: some View {
        ZStack {
            Color(hex: "3A3A3A")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Add Person")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    TextField("Full name...", text: $name)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    TextField("Add a note about this person...", text: $note)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    Task {
                        if note.isEmpty {
                            let person = JournaPerson(
                                id: UUID(),
                                name: name,
                                contactID: nil,
                                notes: []
                            )
                            await MainActor.run {
                                ContactsService.shared.people.append(person)
                                ContactsService.shared.people.sort { $0.name < $1.name }
                            }
                        } else {
                            await ContactsService.shared.savePerson(
                                name: name,
                                notes: note,
                                contactID: nil
                            )
                        }
                        dismiss()
                    }
                }) {
                    Text("Save Person")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "8FA8A8"))
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    var personName: String
    @State private var note = ""
    
    var body: some View {
        ZStack {
            Color(hex: "3A3A3A")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Add Note for \(personName)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    TextField("Add a note...", text: $note)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await ContactsService.shared.savePerson(
                            name: personName,
                            notes: note,
                            contactID: nil
                        )
                        dismiss()
                    }
                }) {
                    Text("Save Note")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "8FA8A8"))
                        .cornerRadius(12)
                }
                .disabled(note.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}
