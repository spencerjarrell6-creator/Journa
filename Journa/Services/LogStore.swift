import Foundation
import Combine
import SwiftData

@MainActor
class LogStore: ObservableObject {
    static let shared = LogStore()
    
    var modelContext: ModelContext?
    
    @Published var logs: [JournaLog] = []
    
    func setup(context: ModelContext) {
        self.modelContext = context
        fetch()
    }
    
    func fetch() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<JournaLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        logs = (try? context.fetch(descriptor)) ?? []
    }
    
    @discardableResult
    func saveLog(rawText: String, segments: [TaggedSegment], importSource: String? = nil, importContact: String? = nil) -> JournaLog {
        guard let context = modelContext else {
            return JournaLog(title: "Journal Entry", rawText: rawText)
        }
        let title = segments.first(where: { $0.type == .log })?.text ?? "Journal Entry"
        let log = JournaLog(
            title: title,
            rawText: rawText,
            date: Date(),
            segments: segments,
            isPinned: false,
            importSource: importSource,
            importContact: importContact
        )
        context.insert(log)
        try? context.save()
        fetch()
        return log
    }
    
    func delete(_ log: JournaLog) {
        guard let context = modelContext else { return }
        context.delete(log)
        try? context.save()
        fetch()
    }
    
    func save() {
        try? modelContext?.save()
        fetch()
    }
}
