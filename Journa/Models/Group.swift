import Foundation
import SwiftUI
import SwiftData

@Model
class JournaGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var logIDs: [UUID]
    var eventIDs: [UUID]
    var personIDs: [UUID]
    var noteIDs: [UUID]
    var summary: String?
    var createdAt: Date
    
    var color: Color { Color(hex: colorHex) }
    
    init(id: UUID = UUID(), name: String, colorHex: String = JournaGroup.randomColor(), logIDs: [UUID] = [], eventIDs: [UUID] = [], personIDs: [UUID] = [], noteIDs: [UUID] = [], summary: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.logIDs = logIDs
        self.eventIDs = eventIDs
        self.personIDs = personIDs
        self.noteIDs = noteIDs
        self.summary = summary
        self.createdAt = createdAt
    }
    
    static let accentColors = [
        "4A9EDB", "E05555", "4CAF50", "F5A623",
        "8FA8A8", "9B59B6", "E67E22", "1ABC9C",
        "E91E8C", "3498DB"
    ]
    
    static func randomColor() -> String {
        accentColors.randomElement() ?? "8FA8A8"
    }
}
