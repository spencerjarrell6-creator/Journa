import EventKit
import SwiftUI
import SwiftData
import UserNotifications
import Combine

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()
    let eventStore = EKEventStore()
    
    var modelContext: ModelContext?
    
    @Published var journaEvents: [JournaEvent] = []
    
    func setup(context: ModelContext) {
        self.modelContext = context
        fetch()
    }
    
    func fetch() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<JournaEvent>(
            sortBy: [SortDescriptor(\.date)]
        )
        journaEvents = (try? context.fetch(descriptor)) ?? []
    }
    
    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }
    
    func saveEvent(title: String, date: Date, type: EventType, recurrence: RecurrenceType = .none) async {
        let granted = await requestAccess()
        if granted {
            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600)
            event.calendar = getOrCreateJournaCalendar(type: type)
            if let rule = recurrence.ekRecurrenceRule {
                event.recurrenceRules = [rule]
            }
            try? eventStore.save(event, span: .thisEvent)
        }
        
        guard let context = modelContext else { return }
        let journaEvent = JournaEvent(
            title: title,
            date: date,
            type: type,
            recurrence: recurrence
        )
        context.insert(journaEvent)
        try? context.save()
        fetch()
    }
    
    private func getOrCreateJournaCalendar(type: EventType) -> EKCalendar {
        let calendarName = type == .date ? "Journa – Dates" : "Journa – Logs"
        if let existing = eventStore.calendars(for: .event)
            .first(where: { $0.title == calendarName }) {
            return existing
        }
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarName
        calendar.cgColor = type == .date ? UIColor.red.cgColor : UIColor.green.cgColor
        calendar.source = eventStore.defaultCalendarForNewEvents?.source
        try? eventStore.saveCalendar(calendar, commit: true)
        return calendar
    }
    
    func scheduleNotification(for event: JournaEvent) {
        let eventTitle = event.title
        let eventID = event.id.uuidString
        let eventDate = event.date
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Journa Reminder"
            content.body = eventTitle
            content.sound = .default
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: eventDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: eventID, content: content, trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func removeNotification(for event: JournaEvent) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [event.id.uuidString]
        )
    }
    
    func delete(_ event: JournaEvent) {
        guard let context = modelContext else { return }
        context.delete(event)
        try? context.save()
        fetch()
    }
    
    func save() {
        try? modelContext?.save()
        fetch()
    }
    
    func parseDate(from text: String) -> Date {
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.date.rawValue
        )
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector?.matches(in: text, range: range)
        return matches?.first?.date ?? Date()
    }
    
    func events(for date: Date) -> [JournaEvent] {
        var result: [JournaEvent] = []
        for event in journaEvents {
            if Calendar.current.isDate(event.date, inSameDayAs: date) {
                result.append(event)
                continue
            }
            switch event.recurrence {
            case .none: break
            case .daily:
                if event.date <= date { result.append(event) }
            case .weekly:
                let c = Calendar.current.dateComponents([.weekday], from: event.date)
                let t = Calendar.current.dateComponents([.weekday], from: date)
                if c.weekday == t.weekday && event.date <= date { result.append(event) }
            case .monthly:
                let c = Calendar.current.dateComponents([.day], from: event.date)
                let t = Calendar.current.dateComponents([.day], from: date)
                if c.day == t.day && event.date <= date { result.append(event) }
            case .yearly:
                let c = Calendar.current.dateComponents([.month, .day], from: event.date)
                let t = Calendar.current.dateComponents([.month, .day], from: date)
                if c.month == t.month && c.day == t.day && event.date <= date { result.append(event) }
            }
        }
        return result
    }
}
