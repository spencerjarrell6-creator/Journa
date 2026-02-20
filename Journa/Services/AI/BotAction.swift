import Foundation

enum BotActionType: String, Codable {
    case createLog
    case editLog
    case deleteLog
    case createEvent
    case editEvent
    case deleteEvent
    case createNote
    case editNote
    case deleteNote
    case createGroup
    case deleteGroup
    case renameGroup
    case recolorGroup
    case addToGroup
    case removeFromGroup
}

struct BotAction: Codable, Identifiable {
    let id: UUID
    let type: BotActionType
    let targetID: String?
    let targetName: String?
    let newValue: String?
    let secondaryValue: String?
    let description: String
    
    init(id: UUID = UUID(), type: BotActionType, targetID: String? = nil, targetName: String? = nil, newValue: String? = nil, secondaryValue: String? = nil, description: String) {
        self.id = id
        self.type = type
        self.targetID = targetID
        self.targetName = targetName
        self.newValue = newValue
        self.secondaryValue = secondaryValue
        self.description = description
    }
}

struct BotResponse: Codable {
    let message: String
    let actions: [BotAction]?
    let requiresConfirmation: Bool
}
