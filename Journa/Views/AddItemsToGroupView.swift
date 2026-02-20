import SwiftUI

struct AddItemsToGroupView: View {
    var group: JournaGroup
    @Environment(\.dismiss) var dismiss
    @ObservedObject var groupStore = GroupStore.shared
    @ObservedObject var logStore = LogStore.shared
    @ObservedObject var calendarService = CalendarService.shared
    @ObservedObject var contactsService = ContactsService.shared
    @State private var selectedTab = 0
    
    var currentGroup: JournaGroup {
        groupStore.groups.first(where: { $0.id == group.id }) ?? group
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 16)
                
                // Header
                HStack {
                    Text("Add to \(group.name)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(group.color)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Tab selector
                HStack(spacing: 0) {
                    ForEach(["Logs", "Events", "People", "Notes"], id: \.self) { tab in
                        let index = ["Logs", "Events", "People", "Notes"].firstIndex(of: tab)!
                        Button(action: { selectedTab = index }) {
                            Text(tab)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTab == index ? .white : .white.opacity(0.4))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedTab == index ?
                                    group.color.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                Divider().background(Color.white.opacity(0.08))
                
                ScrollView {
                    VStack(spacing: 8) {
                        switch selectedTab {
                        case 0:
                            // Logs
                            ForEach(logStore.logs) { log in
                                let isAdded = currentGroup.logIDs.contains(log.id)
                                Button(action: {
                                    if isAdded {
                                        if let i = groupStore.groups.firstIndex(where: { $0.id == group.id }) {
                                            groupStore.groups[i].logIDs.removeAll { $0 == log.id }
                                        }
                                    } else {
                                        groupStore.addLog(log.id, to: group.id)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(isAdded ? group.color : .white.opacity(0.3))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(log.title)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text(log.date.formatted(.dateTime.month().day().year()))
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        Spacer()
                                        // Add full categorization
                                        if !log.segments.filter({ !$0.isRemoved }).isEmpty {
                                            Button(action: {
                                                groupStore.addCategorization(log: log, to: group.id)
                                            }) {
                                                Text("+ All")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(group.color)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(group.color.opacity(0.12))
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .background(isAdded ?
                                        group.color.opacity(0.08) :
                                        Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            
                        case 1:
                            // Events
                            ForEach(calendarService.journaEvents.sorted { $0.date > $1.date }) { event in
                                let isAdded = currentGroup.eventIDs.contains(event.id)
                                Button(action: {
                                    if isAdded {
                                        if let i = groupStore.groups.firstIndex(where: { $0.id == group.id }) {
                                            groupStore.groups[i].eventIDs.removeAll { $0 == event.id }
                                        }
                                    } else {
                                        groupStore.addEvent(event.id, to: group.id)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(isAdded ? group.color : .white.opacity(0.3))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(event.title)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text(event.date.formatted(.dateTime.month().day().year()))
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        Spacer()
                                    }
                                    .padding(14)
                                    .background(isAdded ?
                                        group.color.opacity(0.08) :
                                        Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            
                        case 2:
                            // People
                            ForEach(contactsService.people) { person in
                                let isAdded = currentGroup.personIDs.contains(person.id)
                                Button(action: {
                                    if isAdded {
                                        if let i = groupStore.groups.firstIndex(where: { $0.id == group.id }) {
                                            groupStore.groups[i].personIDs.removeAll { $0 == person.id }
                                        }
                                    } else {
                                        groupStore.addPerson(person.id, to: group.id)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(isAdded ? group.color : .white.opacity(0.3))
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "4A9EDB").opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            Text(String(person.name.prefix(1)))
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Color(hex: "4A9EDB"))
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(person.name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text("\(person.notes.count) notes")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        Spacer()
                                    }
                                    .padding(14)
                                    .background(isAdded ?
                                        group.color.opacity(0.08) :
                                        Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            
                        case 3:
                            // Individual notes
                            ForEach(contactsService.people) { person in
                                if !person.notes.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(person.name.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.3))
                                            .tracking(2)
                                            .padding(.horizontal, 4)
                                        
                                        ForEach(person.notes.filter { !$0.isLocked }) { note in                                            let isAdded = currentGroup.noteIDs.contains(note.id)
                                            Button(action: {
                                                if isAdded {
                                                    if let i = groupStore.groups.firstIndex(where: { $0.id == group.id }) {
                                                        groupStore.groups[i].noteIDs.removeAll { $0 == note.id }
                                                    }
                                                } else {
                                                    groupStore.addNote(note.id, to: group.id)
                                                }
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(isAdded ? group.color : .white.opacity(0.3))
                                                    Text(note.text)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.white.opacity(0.8))
                                                        .lineLimit(2)
                                                    Spacer()
                                                }
                                                .padding(14)
                                                .background(isAdded ?
                                                    group.color.opacity(0.08) :
                                                    Color.white.opacity(0.04))
                                                .cornerRadius(10)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }
}
