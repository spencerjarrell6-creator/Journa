import SwiftUI
import SwiftData

@Model
class TaggedSegment {
    var id: UUID
    var text: String
    var typeStrings: [String]
    var isRemoved: Bool
    var contactName: String?
    
    var types: [SegmentType] {
        get { typeStrings.compactMap { SegmentType(rawValue: $0) } }
        set { typeStrings = newValue.map { $0.rawValue } }
    }
    
    var type: SegmentType { types.first ?? .log }
    
    init(id: UUID = UUID(), text: String, types: [SegmentType], isRemoved: Bool = false, contactName: String? = nil) {
        self.id = id
        self.text = text
        self.typeStrings = types.map { $0.rawValue }
        self.isRemoved = isRemoved
        self.contactName = contactName
    }
}

enum SegmentType: String, Codable, Hashable {
    case date
    case person
    case log
    
    var color: Color {
        switch self {
        case .date:   return Color(hex: "E05555")
        case .person: return Color(hex: "4A9EDB")
        case .log:    return Color(hex: "4CAF50")
        }
    }
    
    var destination: String {
        switch self {
        case .date:   return "Calendar"
        case .person: return "People"
        case .log:    return "Journal Log"
        }
    }
    
    var icon: String {
        switch self {
        case .date:   return "calendar"
        case .person: return "person.fill"
        case .log:    return "book.fill"
        }
    }
}
