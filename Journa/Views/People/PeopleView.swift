import SwiftUI

struct PeopleView: View {
    @ObservedObject var contactsService = ContactsService.shared
    @State private var showingAddPerson = false
    @State private var searchText = ""
    @State private var allActive: Bool = true
    @State private var personToDelete: JournaPerson? = nil
    
    func isLocked(_ person: JournaPerson) -> Bool {
        UserDefaults.standard.bool(forKey: "locked_\(person.id)")
    }
    
    var filteredPeople: [JournaPerson] {
        let people = searchText.isEmpty ? contactsService.people : contactsService.people.filter {
            if isLocked($0) {
                return $0.name.lowercased().contains(searchText.lowercased())
            }
            return $0.name.lowercased().contains(searchText.lowercased()) ||
                   $0.notes.contains { $0.text.lowercased().contains(searchText.lowercased()) }
        }
        return people.sorted { a, b in
            if a.isPinned == b.isPinned { return a.name < b.name }
            return a.isPinned && !b.isPinned
        }
    }
    
    var groupedPeople: [(String, [JournaPerson])] {
        let pinned = filteredPeople.filter { $0.isPinned }
        let unpinned = filteredPeople.filter { !$0.isPinned }
        
        var result: [(String, [JournaPerson])] = []
        
        if !pinned.isEmpty {
            result.append(("Pinned", pinned))
        }
        
        if !searchText.isEmpty {
            result.append(("RESULTS", unpinned))
            return result
        }
        
        let letters = Set(unpinned.map { String($0.name.prefix(1)).uppercased() }).sorted()
        for letter in letters {
            result.append((letter, unpinned.filter { String($0.name.prefix(1)).uppercased() == letter }))
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Top bar
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Image("journa")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                            Text("People")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Button(action: {
                                allActive.toggle()
                                for i in contactsService.people.indices {
                                    contactsService.people[i].isActive = allActive
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: allActive ? "person.fill.checkmark" : "person.fill.xmark")
                                        .font(.system(size: 13))
                                    Text(allActive ? "All On" : "All Off")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(allActive ? Color(hex: "4A9EDB") : .white.opacity(0.3))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(allActive ? Color(hex: "4A9EDB").opacity(0.12) : Color.white.opacity(0.06))
                                .cornerRadius(8)
                            }
                            
                            Button(action: { showingAddPerson = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(10)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.3))
                            .font(.system(size: 14))
                        TextField("Search people and notes...", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.3))
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    if filteredPeople.isEmpty && !searchText.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No results for \"\(searchText)\"")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                    } else if contactsService.people.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.2")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No people yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Add someone or mention a contact\nin a journal entry.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.2))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(groupedPeople, id: \.0) { letter, people in
                                Section {
                                    ForEach(people) { person in
                                        HStack(spacing: 14) {
                                            NavigationLink(destination: PersonDetailView(person: person)) {
                                                HStack(spacing: 14) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(person.isActive ?
                                                                  Color(hex: "4A9EDB").opacity(0.15) :
                                                                  Color.white.opacity(0.05))
                                                            .frame(width: 42, height: 42)
                                                        Text(String(person.name.prefix(1)))
                                                            .font(.system(size: 17, weight: .bold))
                                                            .foregroundColor(person.isActive ?
                                                                             Color(hex: "4A9EDB") :
                                                                             Color.white.opacity(0.2))
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        HStack(spacing: 6) {
                                                            HighlightedText(
                                                                text: person.name,
                                                                query: searchText,
                                                                baseColor: person.isActive ? .white : .white.opacity(0.3)
                                                            )
                                                            .font(.system(size: 16, weight: .semibold))
                                                            
                                                            if person.isPinned {
                                                                Image(systemName: "pin.fill")
                                                                    .font(.system(size: 10))
                                                                    .foregroundColor(Color(hex: "8FA8A8"))
                                                                    .rotationEffect(.degrees(45))
                                                            }
                                                        }
                                                        
                                                        // Note preview — locked people never show note content
                                                        if isLocked(person) {
                                                            HStack(spacing: 4) {
                                                                Image(systemName: "lock.fill")
                                                                    .font(.system(size: 10))
                                                                Text("Locked")
                                                                    .font(.system(size: 12))
                                                            }
                                                            .foregroundColor(.white.opacity(0.2))
                                                        } else if !searchText.isEmpty,
                                                                  let matchingNote = person.notes.first(where: {
                                                                      $0.text.lowercased().contains(searchText.lowercased())
                                                                  }) {
                                                            HighlightedText(
                                                                text: matchingNote.text,
                                                                query: searchText,
                                                                baseColor: .white.opacity(0.4)
                                                            )
                                                            .font(.system(size: 12))
                                                            .lineLimit(1)
                                                        } else {
                                                            Text(person.notes.last?.text ?? "")
                                                                .font(.system(size: 12))
                                                                .foregroundColor(.white.opacity(0.4))
                                                                .lineLimit(1)
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    VStack(alignment: .trailing, spacing: 3) {
                                                        Text("\(person.notes.count)")
                                                            .font(.system(size: 13, weight: .bold))
                                                            .foregroundColor(person.isActive ?
                                                                             Color(hex: "4A9EDB") :
                                                                             Color.white.opacity(0.2))
                                                        Text("notes")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.white.opacity(0.3))
                                                    }
                                                }
                                            }
                                            
                                            Toggle("", isOn: Binding(
                                                get: { person.isActive },
                                                set: { newValue in
                                                    if let index = contactsService.people.firstIndex(where: { $0.id == person.id }) {
                                                        contactsService.people[index].isActive = newValue
                                                    }
                                                }
                                            ))
                                            .tint(Color(hex: "4A9EDB"))
                                            .labelsHidden()
                                        }
                                        .listRowBackground(Color.white.opacity(0.04))
                                        .listRowSeparatorTint(Color.white.opacity(0.06))
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                if let index = contactsService.people.firstIndex(where: { $0.id == person.id }) {
                                                    contactsService.people[index].isPinned.toggle()
                                                }
                                            } label: {
                                                Label(person.isPinned ? "Unpin" : "Pin", systemImage: person.isPinned ? "pin.slash" : "pin.fill")
                                            }
                                            .tint(Color(hex: "8FA8A8"))
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button {
                                                personToDelete = person
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .tint(Color(hex: "FF6B6B"))
                                        }
                                    }
                                } header: {
                                    Text(letter)
                                        .font(.system(
                                            size: letter == "Pinned" || letter == "RESULTS" ? 13 : 26,
                                            weight: letter == "Pinned" || letter == "RESULTS" ? .bold : .black
                                        ))
                                        .foregroundColor(
                                            letter == "Pinned" || letter == "RESULTS" ?
                                            Color(hex: "8FA8A8") :
                                            Color(hex: "4A9EDB").opacity(0.6)
                                        )
                                        .tracking(letter == "Pinned" || letter == "RESULTS" ? 2 : 0)
                                        .textCase(nil)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonView()
            }
            .task {
                await ContactsService.shared.loadAllContacts()
            }
            .confirmationDialog(
                "Delete \(personToDelete?.name ?? "")?",
                isPresented: Binding(
                    get: { personToDelete != nil },
                    set: { if !$0 { personToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete \(personToDelete?.name ?? "")", role: .destructive) {
                    if let person = personToDelete,
                       let index = contactsService.people.firstIndex(where: { $0.id == person.id }) {
                        contactsService.people.remove(at: index)
                    }
                    personToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    personToDelete = nil
                }
            } message: {
                Text("This will permanently remove \(personToDelete?.name ?? "") and all their notes.")
            }
        }
    }
}
