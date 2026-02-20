import SwiftUI
import SwiftData
import Contacts
import EventKit
import UserNotifications

@main
struct JournaApp: App {
    
    let container: ModelContainer
    
    init() {
        // API key set via Settings
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        do {
            container = try ModelContainer(for:
                JournaLog.self,
                TaggedSegment.self,
                JournaPerson.self,
                PersonNote.self,
                JournaEvent.self,
                JournaGroup.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .modelContainer(container)
                .onAppear {
                    let context = container.mainContext
                    LogStore.shared.setup(context: context)
                    CalendarService.shared.setup(context: context)
                    ContactsService.shared.setup(context: context)
                    GroupStore.shared.setup(context: context)
                    requestPermissions()
                }
        }
    }
    
    func requestPermissions() {
        CNContactStore().requestAccess(for: .contacts) { _, _ in }
        EKEventStore().requestFullAccessToEvents { _, _ in }
    }
}
