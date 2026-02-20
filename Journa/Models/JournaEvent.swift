import Foundation
import SwiftData
import EventKit

@Model
class JournaEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var typeRaw: String
    var recurrenceRaw: String
    var ekEventID: String
    var hasNotification: Bool
    
    var type: EventType {
        get { EventType(rawValue: typeRaw) ?? .log }
        set { typeRaw = newValue.rawValue }
    }
    
    var recurrence: RecurrenceType {
        get { RecurrenceType(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), title: String, date: Date, type: EventType, recurrence: RecurrenceType = .none, ekEventID: String = "", hasNotification: Bool = false) {
        self.id = id
        self.title = title
        self.date = date
        self.typeRaw = type.rawValue
        self.recurrenceRaw = recurrence.rawValue
        self.ekEventID = ekEventID
        self.hasNotification = hasNotification
    }
}

enum EventType: String, Codable {
    case date
    case log
}

enum RecurrenceType: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var ekRecurrenceRule: EKRecurrenceRule? {
        switch self {
        case .none: return nil
        case .daily: return EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
        case .weekly: return EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
        case .monthly: return EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)
        case .yearly: return EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil)
        }
    }
}
