import Contacts
import SwiftUI
import SwiftData
import Combine

@MainActor
class ContactsService: ObservableObject {
    static let shared = ContactsService()
    
    var modelContext: ModelContext?
    
    @Published var people: [JournaPerson] = []
    
    func setup(context: ModelContext) {
        self.modelContext = context
        fetch()
    }
    
    func fetch() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<JournaPerson>(
            sortBy: [SortDescriptor(\.name)]
        )
        people = (try? context.fetch(descriptor)) ?? []
    }
    
    func requestAccess() async -> Bool {
        let store = CNContactStore()
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }
    
    func fetchContacts() async -> [CNContact] {
        let store = CNContactStore()
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        return await Task.detached(priority: .userInitiated) {
            var contacts: [CNContact] = []
            try? store.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
            return contacts
        }.value
    }
    
    func loadAllContacts() async {
        let granted = await requestAccess()
        guard granted else { return }
        let contacts = await fetchContacts()
        guard let context = modelContext else { return }
        
        for contact in contacts {
            let name = "\(contact.givenName) \(contact.familyName)"
                .trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            if !people.contains(where: { $0.name.lowercased() == name.lowercased() }) {
                let person = JournaPerson(
                    name: name,
                    contactID: contact.identifier
                )
                context.insert(person)
            }
        }
        try? context.save()
        fetch()
    }
    
    func isLikelyNickname(_ input: String, for contactName: String) -> Bool {
        let input = input.lowercased().trimmingCharacters(in: .whitespaces)
        let name = contactName.lowercased().trimmingCharacters(in: .whitespaces)
        guard input.count >= 2, name.count >= 2 else { return false }
        if input == name { return true }
        let nameWords = name.components(separatedBy: " ")
        if nameWords.contains(input) { return true }
        if input.count >= 3 && name.hasPrefix(input) { return true }
        if name.count >= 3 && input.hasPrefix(name) { return true }
        return false
    }
    
    func matchContacts(for text: String) async -> [JournaPerson] {
        let textLower = text.lowercased()
        return people.filter { person in
            guard person.isActive else { return false }
            let firstName = person.name.components(separatedBy: " ").first?.lowercased() ?? ""
            let fullName = person.name.lowercased()
            return textLower == firstName || textLower == fullName ||
                   isLikelyNickname(textLower, for: firstName)
        }
    }
    
    func getDeviceOwnerName() -> [String] {
        var names: [String] = []
        let deviceName = UIDevice.current.name.lowercased()
        let cleaned = deviceName
            .replacingOccurrences(of: "'s iphone", with: "")
            .replacingOccurrences(of: "'s ipad", with: "")
            .replacingOccurrences(of: "s iphone", with: "")
            .replacingOccurrences(of: "iphone", with: "")
            .replacingOccurrences(of: "ipad", with: "")
            .trimmingCharacters(in: .whitespaces)
        if !cleaned.isEmpty {
            names.append(cleaned)
            cleaned.components(separatedBy: " ").forEach { names.append($0) }
        }
        return names
    }
    
    func savePerson(name: String, notes: String, contactID: String?, logID: UUID? = nil) async {
        guard let context = modelContext else { return }
        if let existing = people.first(where: {
            $0.name.lowercased() == name.lowercased() ||
            ($0.contactID != nil && $0.contactID == contactID)
        }) {
            let note = PersonNote(text: notes, date: Date(), logID: logID)
            context.insert(note)
            existing.notes.append(note)
        } else {
            let note = PersonNote(text: notes, date: Date(), logID: logID)
            context.insert(note)
            let person = JournaPerson(
                name: name,
                contactID: contactID,
                notes: notes.isEmpty ? [] : [note]
            )
            context.insert(person)
        }
        try? context.save()
        fetch()
    }
    
    func extractName(from text: String) -> String {
        text.components(separatedBy: " ").first ?? "Unknown"
    }
}
