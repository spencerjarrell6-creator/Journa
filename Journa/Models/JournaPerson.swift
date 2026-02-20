import Foundation
import SwiftData

@Model
class JournaPerson {
    @Attribute(.unique) var id: UUID
    var name: String
    var contactID: String?
    var notes: [PersonNote]
    var isActive: Bool
    var isPinned: Bool
    
    init(id: UUID = UUID(), name: String, contactID: String? = nil, notes: [PersonNote] = [], isActive: Bool = true, isPinned: Bool = false) {
        self.id = id
        self.name = name
        self.contactID = contactID
        self.notes = notes
        self.isActive = isActive
        self.isPinned = isPinned
    }
}

@Model
class PersonNote {
    var id: UUID
    var text: String
    var date: Date
    var logID: UUID?
    var isLocked: Bool
    
    init(id: UUID = UUID(), text: String, date: Date = Date(), logID: UUID? = nil, isLocked: Bool = false) {
        self.id = id
        self.text = text
        self.date = date
        self.logID = logID
        self.isLocked = isLocked
    }
}
