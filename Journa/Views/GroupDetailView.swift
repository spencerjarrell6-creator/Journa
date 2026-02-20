import SwiftUI

struct GroupDetailView: View {
    var group: JournaGroup
    @ObservedObject var groupStore = GroupStore.shared
    @ObservedObject var logStore = LogStore.shared
    @ObservedObject var calendarService = CalendarService.shared
    @ObservedObject var contactsService = ContactsService.shared
    @StateObject private var premium = PremiumManager.shared
    @State private var showAddItems = false
    @State private var showEditGroup = false
    @State private var isSummarizing = false
    @State private var showPaywall = false
    @Environment(\.dismiss) var dismiss
    
    var currentGroup: JournaGroup {
        groupStore.groups.first(where: { $0.id == group.id }) ?? group
    }
    
    var logs: [JournaLog] {
        logStore.logs.filter { currentGroup.logIDs.contains($0.id) }
    }
    
    var events: [JournaEvent] {
        calendarService.journaEvents.filter { currentGroup.eventIDs.contains($0.id) }
    }
    
    var people: [JournaPerson] {
        contactsService.people.filter { currentGroup.personIDs.contains($0.id) }
    }
    
    var notes: [(person: JournaPerson, note: PersonNote)] {
        var result: [(JournaPerson, PersonNote)] = []
        for person in contactsService.people {
            for note in person.notes {
                if currentGroup.noteIDs.contains(note.id) {
                    result.append((person, note))
                }
            }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(currentGroup.color.opacity(0.2))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(currentGroup.color)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentGroup.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Created \(currentGroup.createdAt.formatted(.dateTime.month().day().year()))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            
                            // Edit button
                            Button(action: { showEditGroup = true }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(10)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Add items button
                        Button(action: { showAddItems = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 13))
                                Text("Add Items")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(currentGroup.color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(currentGroup.color.opacity(0.12))
                            .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Divider().background(Color.white.opacity(0.08))
                    
                    // AI Summary — premium only
                    if premium.isPremium {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("AI SUMMARY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                                    .tracking(2)
                                Spacer()
                                Button(action: {
                                    Task { await summarize() }
                                }) {
                                    HStack(spacing: 5) {
                                        if isSummarizing {
                                            ProgressView()
                                                .tint(currentGroup.color)
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 11))
                                        }
                                        Text(isSummarizing ? "Summarizing..." : "Summarize")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(currentGroup.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(currentGroup.color.opacity(0.12))
                                    .cornerRadius(8)
                                }
                                .disabled(isSummarizing)
                            }
                            .padding(.horizontal, 20)
                            
                            if let summary = currentGroup.summary {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(summary.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                                        HStack(alignment: .top, spacing: 10) {
                                            Circle()
                                                .fill(currentGroup.color)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 6)
                                            Text(line.hasPrefix("•") ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.8))
                                                .lineSpacing(3)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(currentGroup.color.opacity(0.07))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            } else {
                                Text("Tap Summarize to generate an AI summary of everything in this group.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.3))
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.08))
                    }
                    
                    // Logs
                    if !logs.isEmpty {
                        GroupSection(title: "LOGS", icon: "book.fill", color: Color(hex: "4CAF50")) {
                            ForEach(logs) { log in
                                NavigationLink(destination: LogDetailView(log: log)) {
                                    HStack(spacing: 12) {
                                        Rectangle()
                                            .fill(Color(hex: "4CAF50"))
                                            .frame(width: 3)
                                            .cornerRadius(2)
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
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(12)
                                    .background(Color(hex: "4CAF50").opacity(0.07))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Calendar events
                    if !events.isEmpty {
                        GroupSection(title: "CALENDAR", icon: "calendar", color: Color(hex: "E05555")) {
                            ForEach(events) { event in
                                HStack(spacing: 12) {
                                    Rectangle()
                                        .fill(Color(hex: "E05555"))
                                        .frame(width: 3)
                                        .cornerRadius(2)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(event.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(event.date.formatted(.dateTime.month().day().year().hour().minute()))
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(hex: "E05555").opacity(0.07))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    // People
                    if !people.isEmpty {
                        GroupSection(title: "PEOPLE", icon: "person.fill", color: Color(hex: "4A9EDB")) {
                            ForEach(people) { person in
                                NavigationLink(destination: PersonDetailView(person: person)) {
                                    HStack(spacing: 12) {
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
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(12)
                                    .background(Color(hex: "4A9EDB").opacity(0.07))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Notes
                    if !notes.isEmpty {
                        GroupSection(title: "NOTES", icon: "note.text", color: Color(hex: "F5A623")) {
                            ForEach(notes, id: \.note.id) { person, note in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(note.text)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    Text("From \(person.name) · \(note.date.formatted(.dateTime.month().day().year()))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(12)
                                .background(Color(hex: "F5A623").opacity(0.07))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    // Empty state
                    if logs.isEmpty && events.isEmpty && people.isEmpty && notes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.15))
                            Text("This group is empty")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Tap \"Add Items\" to start adding\nlogs, events, people, and notes.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.2))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddItems) {
            AddItemsToGroupView(group: currentGroup)
        }
        .sheet(isPresented: $showEditGroup) {
            EditGroupView(group: currentGroup)
        }
        .sheet(isPresented: $showPaywall) {
            JournAIPaywallView()
        }
        .onChange(of: currentGroup.id) {
            // If group was deleted, dismiss
            if groupStore.groups.first(where: { $0.id == group.id }) == nil {
                dismiss()
            }
        }
    }
    
    func summarize() async {
        isSummarizing = true
        var content = ""
        for log in logs { content += "Log: \(log.title)\n\(log.rawText)\n\n" }
        for event in events { content += "Event: \(event.title) on \(event.date.formatted(.dateTime.month().day().year()))\n\n" }
        for person in people {
            content += "Person: \(person.name)\n"
            for note in person.notes { content += "- \(note.text)\n" }
            content += "\n"
        }
        for (person, note) in notes { content += "Note about \(person.name): \(note.text)\n\n" }
        
        let prompt = """
        Summarize the following group of journal content into concise bullet points.
        Each bullet should capture a key insight, event, or fact.
        Keep each bullet to one sentence. Return only the bullets, one per line, starting with •
        
        Content:
        \(content)
        """
        
        do {
            let body: [String: Any] = [
                "model": "claude-opus-4-6",
                "max_tokens": 512,
                "messages": [["role": "user", "content": prompt]]
            ]
            var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            let summary = response.content.first?.text ?? ""
            await MainActor.run {
                if let i = groupStore.groups.firstIndex(where: { $0.id == group.id }) {
                    groupStore.groups[i].summary = summary
                }
            }
        } catch {
            print("Summary failed: \(error)")
        }
        isSummarizing = false
    }
}

// MARK: - Group Section
struct GroupSection<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(2)
            }
            .padding(.horizontal, 20)
            VStack(spacing: 8) { content }
                .padding(.horizontal, 20)
        }
    }
}
