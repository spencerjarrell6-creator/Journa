import Foundation
import SwiftData
import Combine

@MainActor
class GroupStore: ObservableObject {
    static let shared = GroupStore()
    
    var modelContext: ModelContext?
    
    @Published var groups: [JournaGroup] = []
    
    func setup(context: ModelContext) {
        self.modelContext = context
        fetch()
    }
    
    func fetch() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<JournaGroup>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        groups = (try? context.fetch(descriptor)) ?? []
    }
    
    @discardableResult
    func createGroup(name: String, colorHex: String? = nil) -> JournaGroup {
        guard let context = modelContext else {
            return JournaGroup(name: name)
        }
        let group = JournaGroup(name: name, colorHex: colorHex ?? JournaGroup.randomColor())
        context.insert(group)
        try? context.save()
        fetch()
        return group
    }
    
    func renameGroup(_ groupID: UUID, to newName: String) {
        if let i = groups.firstIndex(where: { $0.id == groupID }) {
            groups[i].name = newName
            try? modelContext?.save()
            fetch()
        }
    }
    
    func recolorGroup(_ groupID: UUID, colorHex: String) {
        if let i = groups.firstIndex(where: { $0.id == groupID }) {
            groups[i].colorHex = colorHex
            try? modelContext?.save()
            fetch()
        }
    }
    
    func addLog(_ logID: UUID, to groupID: UUID) {
        if let i = groups.firstIndex(where: { $0.id == groupID }) {
            if !groups[i].logIDs.contains(logID) {
                groups[i].logIDs.append(logID)
                try? modelContext?.save()
            }
        }
    }
    
    func addEvent(_ eventID: UUID, to groupID: UUID) {
        if let i = groups.firstIndex(where: { $0.id == groupID }) {
            if !groups[i].eventIDs.contains(eventID) {
                groups[i].eventIDs.append(eventID)
                try? modelContext?.save()
            }
        }
    }
    
    func addPerson(_ personID: UUID, to groupID: UUID) {
        if let i = groups.firstIndex(where: { $0.id == groupID }) {
            if !groups[i].personIDs.contains(personID) {
                groups[i].personIDs.append(personID)
                try? modelContext?.save()
            }
        }
    }
    
    func addNote(_ noteID: UUID, to groupID: UUID) {
        if let i = groups.firstIndex(where: { $0.id == groupID }) {
            if !groups[i].noteIDs.contains(noteID) {
                groups[i].noteIDs.append(noteID)
                try? modelContext?.save()
            }
        }
    }
    
    func addCategorization(log: JournaLog, to groupID: UUID) {
        if let i = groups.firstIndex(where: { $0.id == groupID }) {
            if !groups[i].logIDs.contains(log.id) {
                groups[i].logIDs.append(log.id)
            }
            for segment in log.segments where !segment.isRemoved {
                if segment.types.contains(.person),
                   let name = segment.contactName,
                   let person = ContactsService.shared.people.first(where: {
                       $0.name.lowercased() == name.lowercased()
                   }) {
                    if !groups[i].personIDs.contains(person.id) {
                        groups[i].personIDs.append(person.id)
                    }
                }
                if segment.types.contains(.date),
                   let event = CalendarService.shared.journaEvents.first(where: {
                       $0.title == segment.text
                   }) {
                    if !groups[i].eventIDs.contains(event.id) {
                        groups[i].eventIDs.append(event.id)
                    }
                }
            }
            try? modelContext?.save()
        }
    }
    
    func remove(_ groupID: UUID) {
        guard let context = modelContext,
              let group = groups.first(where: { $0.id == groupID }) else { return }
        context.delete(group)
        try? context.save()
        fetch()
    }
    
    func groupsContaining(logID: UUID) -> [JournaGroup] {
        groups.filter { $0.logIDs.contains(logID) }
    }
    
    func groupsContaining(personID: UUID) -> [JournaGroup] {
        groups.filter { $0.personIDs.contains(personID) }
    }
    
    func groupsContaining(eventID: UUID) -> [JournaGroup] {
        groups.filter { $0.eventIDs.contains(eventID) }
    }
}
