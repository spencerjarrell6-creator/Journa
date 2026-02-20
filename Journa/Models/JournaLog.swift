import Foundation
import SwiftData

@Model
class JournaLog {
    @Attribute(.unique) var id: UUID
    var title: String
    var rawText: String
    var date: Date
    var segments: [TaggedSegment]
    var isPinned: Bool
    var importSource: String?  // "instagram", "messages", etc.
    var importContact: String? // contact name the import is from
    
    init(id: UUID = UUID(), title: String, rawText: String, date: Date = Date(), segments: [TaggedSegment] = [], isPinned: Bool = false, importSource: String? = nil, importContact: String? = nil) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.date = date
        self.segments = segments
        self.isPinned = isPinned
        self.importSource = importSource
        self.importContact = importContact
    }
}
