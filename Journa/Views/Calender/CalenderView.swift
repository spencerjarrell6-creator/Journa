import SwiftUI
import Combine
import UserNotifications

struct CalendarView: View {
    @ObservedObject var calendarService = CalendarService.shared
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false
    @State private var editingEvent: JournaEvent? = nil
    @State private var searchText = ""
    @State private var isSearching = false
    
    var eventsForSelectedDate: [JournaEvent] {
        calendarService.events(for: selectedDate)
    }
    
    var searchResults: [JournaEvent] {
        guard !searchText.isEmpty else { return [] }
        return calendarService.journaEvents.filter { event in
            event.title.lowercased().contains(searchText.lowercased()) ||
            event.date.formatted(.dateTime.month().day().year()).lowercased().contains(searchText.lowercased())
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Top bar
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Image("journa")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                        Text("Calendar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 14))
                    TextField("Search events and dates...", text: $searchText)
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                        .onChange(of: searchText) {
                            isSearching = !searchText.isEmpty
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearching = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                if isSearching {
                    // Search results
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            if searchResults.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.15))
                                    Text("No results for \"\(searchText)\"")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.25))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                Text("RESULTS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "8FA8A8"))
                                    .tracking(2)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 4)
                                
                                ForEach(searchResults) { event in
                                    SearchEventRow(event: event, query: searchText, onEdit: {
                                        editingEvent = event
                                    }, onDelete: {
                                        calendarService.journaEvents.removeAll { $0.id == event.id }
                                        calendarService.removeNotification(for: event)
                                    }, onToggleNotification: {
                                        if let index = calendarService.journaEvents.firstIndex(where: { $0.id == event.id }) {
                                            let isOn = !calendarService.journaEvents[index].hasNotification
                                            calendarService.journaEvents[index].hasNotification = isOn
                                            if isOn {
                                                calendarService.scheduleNotification(for: calendarService.journaEvents[index])
                                            } else {
                                                calendarService.removeNotification(for: event)
                                            }
                                        }
                                    })
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                } else {
                    // Normal calendar view
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color(hex: "8FA8A8"))
                    .colorScheme(.dark)
                    .padding(.horizontal, 12)
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            if eventsForSelectedDate.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.15))
                                    Text("No events logged")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.25))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                            } else {
                                ForEach(eventsForSelectedDate) { event in
                                    CalendarEventRow(event: event, onEdit: {
                                        editingEvent = event
                                    }, onDelete: {
                                        calendarService.journaEvents.removeAll { $0.id == event.id }
                                        calendarService.removeNotification(for: event)
                                    }, onToggleNotification: {
                                        if let index = calendarService.journaEvents.firstIndex(where: { $0.id == event.id }) {
                                            let isOn = !calendarService.journaEvents[index].hasNotification
                                            calendarService.journaEvents[index].hasNotification = isOn
                                            if isOn {
                                                calendarService.scheduleNotification(for: calendarService.journaEvents[index])
                                            } else {
                                                calendarService.removeNotification(for: event)
                                            }
                                        }
                                    })
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(selectedDate: selectedDate)
        }
        .sheet(item: $editingEvent) { event in
            EditEventView(event: event)
        }
    }
}

// MARK: - Search Event Row
struct SearchEventRow: View {
    var event: JournaEvent
    var query: String
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onToggleNotification: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(event.type == .date ?
                    Color(hex: "E05555") :
                    Color(hex: "4CAF50"))
                .frame(width: 3)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                HighlightedText(text: event.title, query: query, baseColor: .white)
                    .font(.system(size: 15, weight: .semibold))
                
                HStack(spacing: 6) {
                    HighlightedText(
                        text: event.date.formatted(.dateTime.month().day().year().hour().minute()),
                        query: query,
                        baseColor: .white.opacity(0.4)
                    )
                    .font(.system(size: 12))
                    
                    if event.recurrence != .none {
                        Text("↻ \(event.recurrence.rawValue)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "8FA8A8").opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "8FA8A8").opacity(0.1))
                            .cornerRadius(5)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if event.type == .date {
                    Button(action: onToggleNotification) {
                        Image(systemName: event.hasNotification ? "bell.fill" : "bell")
                            .font(.system(size: 13))
                            .foregroundColor(event.hasNotification ?
                                Color(hex: "8FA8A8") : .white.opacity(0.4))
                            .padding(8)
                            .background(event.hasNotification ?
                                Color(hex: "8FA8A8").opacity(0.15) :
                                Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "FF6B6B").opacity(0.7))
                        .padding(8)
                        .background(Color(hex: "FF6B6B").opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

// MARK: - Event Row
struct CalendarEventRow: View {
    var event: JournaEvent
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onToggleNotification: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(event.type == .date ?
                    Color(hex: "E05555") :
                    Color(hex: "4CAF50"))
                .frame(width: 3)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(event.date.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    if event.recurrence != .none {
                        Text("↻ \(event.recurrence.rawValue)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "8FA8A8").opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "8FA8A8").opacity(0.1))
                            .cornerRadius(5)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if event.type == .date {
                    Button(action: onToggleNotification) {
                        Image(systemName: event.hasNotification ? "bell.fill" : "bell")
                            .font(.system(size: 13))
                            .foregroundColor(event.hasNotification ?
                                Color(hex: "8FA8A8") : .white.opacity(0.4))
                            .padding(8)
                            .background(event.hasNotification ?
                                Color(hex: "8FA8A8").opacity(0.15) :
                                Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "FF6B6B").opacity(0.7))
                        .padding(8)
                        .background(Color(hex: "FF6B6B").opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}
