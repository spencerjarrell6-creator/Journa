import SwiftUI

struct BotDataSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var groupStore = GroupStore.shared
    
    @AppStorage("bot_access_logs") var accessLogs = true
    @AppStorage("bot_access_calendar") var accessCalendar = true
    @AppStorage("bot_access_people") var accessPeople = true
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                // Header
                HStack {
                    Text("Data Access")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "8FA8A8"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Text("Choose what Journa AI can see when answering your questions.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Core data
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CORE DATA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 1) {
                                BotToggleRow(
                                    icon: "books.vertical",
                                    title: "Logs",
                                    subtitle: "\(LogStore.shared.logs.count) entries",
                                    color: Color(hex: "4CAF50"),
                                    isOn: $accessLogs
                                )
                                
                                BotToggleRow(
                                    icon: "calendar",
                                    title: "Calendar",
                                    subtitle: "\(CalendarService.shared.journaEvents.count) events",
                                    color: Color(hex: "E05555"),
                                    isOn: $accessCalendar
                                )
                                
                                BotToggleRow(
                                    icon: "person.2",
                                    title: "People & Notes",
                                    subtitle: "\(ContactsService.shared.people.count) people",
                                    color: Color(hex: "4A9EDB"),
                                    isOn: $accessPeople
                                )
                            }
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // Groups
                        if !groupStore.groups.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("GROUPS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                                    .tracking(2)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 1) {
                                    ForEach(groupStore.groups) { group in
                                        let key = "bot_access_group_\(group.id)"
                                        let binding = Binding<Bool>(
                                            get: { UserDefaults.standard.bool(forKey: key) },
                                            set: { UserDefaults.standard.set($0, forKey: key) }
                                        )
                                        let itemCount = group.logIDs.count + group.eventIDs.count + group.personIDs.count + group.noteIDs.count
                                        
                                        BotToggleRow(
                                            icon: "folder.fill",
                                            title: group.name,
                                            subtitle: "\(itemCount) item\(itemCount == 1 ? "" : "s")",
                                            color: group.color,
                                            isOn: binding
                                        )
                                    }
                                }
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Bot Toggle Row
struct BotToggleRow: View {
    var icon: String
    var title: String
    var subtitle: String
    var color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(color)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
