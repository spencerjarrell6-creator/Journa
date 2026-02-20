import SwiftUI
import LocalAuthentication

struct PersonDetailView: View {
    var person: JournaPerson
    @ObservedObject var contactsService = ContactsService.shared
    @State private var showingAddNote = false
    @State private var isUnlocked = false
    @State private var isLocked: Bool = false
    @State private var authError: String? = nil
    @State private var isSelecting = false
    @State private var selectedNoteIDs: Set<UUID> = []

    var lockKey: String { "locked_\(person.id)" }

    var currentPerson: JournaPerson {
        contactsService.people.first(where: { $0.id == person.id }) ?? person
    }

    var sortedNotes: [PersonNote] {
        let pinned = currentPerson.notes.filter { $0.isPinned }
        let unpinned = currentPerson.notes.filter { !$0.isPinned }
        return pinned + unpinned
    }

    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentPerson.name.uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "4A9EDB"))
                        Text("\(currentPerson.notes.count) notes")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.3))
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        // Select button
                        if !currentPerson.notes.isEmpty {
                            Button(action: {
                                withAnimation {
                                    isSelecting.toggle()
                                    selectedNoteIDs.removeAll()
                                }
                            }) {
                                Text(isSelecting ? "Cancel" : "Select")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isSelecting ? Color(hex: "E05555") : Color(hex: "4A9EDB"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        isSelecting
                                            ? Color(hex: "E05555").opacity(0.12)
                                            : Color(hex: "4A9EDB").opacity(0.12)
                                    )
                                    .cornerRadius(8)
                            }
                        }

                        // Lock toggle
                        Button(action: toggleLock) {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                                .font(.system(size: 16))
                                .foregroundColor(isLocked ? Color(hex: "E05555") : .white.opacity(0.3))
                                .padding(10)
                                .background(isLocked ?
                                    Color(hex: "E05555").opacity(0.12) :
                                    Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Bulk action bar
                if isSelecting && !selectedNoteIDs.isEmpty {
                    HStack(spacing: 12) {
                        Text("\(selectedNoteIDs.count) selected")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))

                        Spacer()

                        Button(action: pinSelected) {
                            HStack(spacing: 5) {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 12))
                                Text("Pin")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "F5A623"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "F5A623").opacity(0.12))
                            .cornerRadius(8)
                        }

                        Button(action: deleteSelected) {
                            HStack(spacing: 5) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12))
                                Text("Delete")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "E05555"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "E05555").opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Divider().background(Color.white.opacity(0.08))

                if isLocked && !isUnlocked {
                    // Locked state
                    Spacer()
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E05555").opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "E05555").opacity(0.7))
                        }

                        Text("Notes are locked")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))

                        if let error = authError {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "FF6B6B"))
                        }

                        Button(action: { authenticate() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 15))
                                Text("Unlock Notes")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color(hex: "4A9EDB"))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()

                } else {
                    if currentPerson.notes.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No notes yet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.25))
                            Text("Journal about \(currentPerson.name) to add notes automatically.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.15))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(sortedNotes) { note in
                                    NoteRow(
                                        note: note,
                                        isSelecting: isSelecting,
                                        isSelected: selectedNoteIDs.contains(note.id),
                                        onTap: {
                                            if isSelecting {
                                                if selectedNoteIDs.contains(note.id) {
                                                    selectedNoteIDs.remove(note.id)
                                                } else {
                                                    selectedNoteIDs.insert(note.id)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                    }

                    Divider().background(Color.white.opacity(0.08))

                    Button(action: { showingAddNote = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15))
                            Text("Add Note Manually")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "8FA8A8"))
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(personName: currentPerson.name)
        }
        .onAppear {
            isLocked = UserDefaults.standard.bool(forKey: lockKey)
        }
    }

    func pinSelected() {
        if let personIndex = ContactsService.shared.people.firstIndex(where: { $0.id == person.id }) {
            for noteID in selectedNoteIDs {
                if let noteIndex = ContactsService.shared.people[personIndex].notes.firstIndex(where: { $0.id == noteID }) {
                    ContactsService.shared.people[personIndex].notes[noteIndex].isPinned.toggle()
                }
            }
        }
        selectedNoteIDs.removeAll()
        isSelecting = false
    }

    func deleteSelected() {
        if let personIndex = ContactsService.shared.people.firstIndex(where: { $0.id == person.id }) {
            ContactsService.shared.people[personIndex].notes.removeAll {
                selectedNoteIDs.contains($0.id)
            }
        }
        selectedNoteIDs.removeAll()
        isSelecting = false
    }

    func toggleLock() {
        if isLocked {
            authenticate {
                isLocked = false
                isUnlocked = false
                UserDefaults.standard.set(false, forKey: lockKey)
            }
        } else {
            isLocked = true
            isUnlocked = false
            UserDefaults.standard.set(true, forKey: lockKey)
        }
    }

    func authenticate(completion: (() -> Void)? = nil) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authError = "Authentication not available"
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock \(currentPerson.name)'s notes"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    isUnlocked = true
                    authError = nil
                    completion?()
                } else {
                    authError = "Authentication failed"
                }
            }
        }
    }
}

// MARK: - Note Row
struct NoteRow: View {
    let note: PersonNote
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isSelecting {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color(hex: "4A9EDB") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "4A9EDB"))
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.top, 4)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    if !isSelecting {
                        Circle()
                            .fill(note.isPinned ? Color(hex: "F5A623") : Color(hex: "4A9EDB"))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if note.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "F5A623"))
                            }
                            Text(note.text)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineSpacing(3)
                        }

                        Text(note.date.formatted(.dateTime.month().day().year()))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))

                        if let logID = note.logID,
                           let originalLog = LogStore.shared.logs.first(where: { $0.id == logID }) {
                            NavigationLink(destination: LogDetailView(log: originalLog)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 10))
                                    Text("View Original Log")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "8FA8A8").opacity(0.8))
                                .padding(.top, 2)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            note.isPinned
                ? Color(hex: "F5A623").opacity(0.07)
                : Color(hex: "4A9EDB").opacity(0.07)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color(hex: "4A9EDB").opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .cornerRadius(10)
        .onTapGesture { onTap() }
    }
}
