import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            JournalView()
                .tabItem {
                    Image(systemName: "pencil")
                    Text("Journal")
                }
            
            PeopleView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("People")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            LogsView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Logs")
                }
            
            GroupsView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Groups")
                }
        }
        .tint(Color(hex: "8FA8A8"))
        .preferredColorScheme(.dark)
    }
}
