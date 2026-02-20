import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date = Date()
    var pendingActions: [BotAction]? = nil
    var isActionCard: Bool = false
}

struct AIBotView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var logStore = LogStore.shared
    @ObservedObject var calendarService = CalendarService.shared
    @ObservedObject var contactsService = ContactsService.shared
    @ObservedObject var groupStore = GroupStore.shared
    
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            text: "Hey! I'm your Journa assistant. Ask me anything or tell me to make changes to your logs, calendar, people, or groups.",
            isUser: false
        )
    ]
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showDataSettings = false
    
    @AppStorage("bot_access_logs") var accessLogs = true
    @AppStorage("bot_access_calendar") var accessCalendar = true
    @AppStorage("bot_access_people") var accessPeople = true
    
    var accessGradientColors: [Color] {
        var colors: [Color] = []
        if accessLogs { colors.append(Color(hex: "4CAF50")) }
        if accessCalendar { colors.append(Color(hex: "E05555")) }
        if accessPeople { colors.append(Color(hex: "4A9EDB")) }
        for group in groupStore.groups {
            if UserDefaults.standard.bool(forKey: "bot_access_group_\(group.id)") {
                colors.append(group.color)
            }
        }
        if colors.isEmpty { colors.append(Color.white.opacity(0.05)) }
        return colors
    }
    
    var accessSummary: String {
        var parts: [String] = []
        if accessLogs { parts.append("Logs") }
        if accessCalendar { parts.append("Calendar") }
        if accessPeople { parts.append("People") }
        let groupCount = groupStore.groups.filter {
            UserDefaults.standard.bool(forKey: "bot_access_group_\($0.id)")
        }.count
        if groupCount > 0 { parts.append("\(groupCount) group\(groupCount == 1 ? "" : "s")") }
        return parts.isEmpty ? "No data access" : parts.joined(separator: " · ")
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            LinearGradient(
                colors: accessGradientColors.map { $0.opacity(0.08) } + [Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("JournAI")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(accessSummary)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Button(action: { showDataSettings = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                if message.isActionCard, let actions = message.pendingActions {
                                    ActionConfirmationCard(
                                        message: message,
                                        actions: actions,
                                        onConfirm: { confirmActions(actions, messageID: message.id) },
                                        onCancel: { cancelActions(messageID: message.id) }
                                    )
                                    .id(message.id)
                                } else {
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            if isLoading {
                                TypingIndicator().id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) {
                        withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: isLoading) {
                        if isLoading {
                            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                // Input
                HStack(spacing: 12) {
                    TextField("Ask or give instructions...", text: $inputText, axis: .vertical)
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(inputText.isEmpty || isLoading ?
                                      Color.white.opacity(0.08) :
                                      Color(hex: "8FA8A8"))
                                .frame(width: 36, height: 36)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(inputText.isEmpty || isLoading ?
                                                 .white.opacity(0.3) : .white)
                        }
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .sheet(isPresented: $showDataSettings) {
            BotDataSettingsView()
        }
    }
    
    func buildContext() -> String {
        var context = ""
        
        if accessLogs {
            let logs = logStore.logs.prefix(20)
            if !logs.isEmpty {
                context += "=== LOGS ===\n"
                for log in logs {
                    context += "ID:\(log.id) [\(log.date.formatted(.dateTime.month().day().year()))] Title:\(log.title)\n\(log.rawText)\n\n"
                }
            }
        }
        
        if accessCalendar {
            let events = calendarService.journaEvents.sorted { $0.date > $1.date }.prefix(30)
            if !events.isEmpty {
                context += "=== CALENDAR EVENTS ===\n"
                for event in events {
                    context += "ID:\(event.id) [\(event.date.formatted(.dateTime.month().day().year().hour().minute()))] \(event.title)\n"
                }
                context += "\n"
            }
        }
        
        if accessPeople {
            if !contactsService.people.isEmpty {
                context += "=== PEOPLE ===\n"
                for person in contactsService.people {
                    context += "Name:\(person.name)\n"
                    for note in person.notes.prefix(10) {
                        context += "  NoteID:\(note.id) - \(note.text)\n"
                    }
                }
                context += "\n"
            }
        }
        
        // Always include groups with their IDs
        if !groupStore.groups.isEmpty {
            context += "=== GROUPS ===\n"
            for group in groupStore.groups {
                context += "ID:\(group.id) Name:\(group.name) Color:\(group.colorHex)\n"
                guard UserDefaults.standard.bool(forKey: "bot_access_group_\(group.id)") else {
                    context += "(content access disabled)\n\n"
                    continue
                }
                let logs = logStore.logs.filter { group.logIDs.contains($0.id) }
                for log in logs { context += "  Log: \(log.title)\n" }
                let events = calendarService.journaEvents.filter { group.eventIDs.contains($0.id) }
                for event in events { context += "  Event: \(event.title)\n" }
                let people = contactsService.people.filter { group.personIDs.contains($0.id) }
                for person in people { context += "  Person: \(person.name)\n" }
                context += "\n"
            }
        }
        
        return context
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""
        isLoading = true
        
        Task {
            let context = buildContext()
            
            let systemPrompt = """
            You are JournAI, a personal journal assistant that can both answer questions AND manipulate journal data.
            
            You have access to the user's data:
            \(context.isEmpty ? "No data accessible — suggest they enable data access via the slider icon." : context)
            
            When the user asks you to CREATE, EDIT, DELETE, or MOVE items, respond with a JSON object in this exact format:
            {
              "message": "Here's what I'll do: [brief description]",
              "requiresConfirmation": true,
              "actions": [
                {
                  "id": "unique-uuid-string",
                  "type": "actionType",
                  "targetID": "item-id-if-known",
                  "targetName": "item-name",
                  "newValue": "new content or value",
                  "secondaryValue": "secondary info like date or new title",
                  "description": "Human readable description of this action"
                }
              ]
            }
            
            Action types:
            createLog, editLog, deleteLog
            createEvent, editEvent, deleteEvent
            createNote, editNote, deleteNote
            createGroup, deleteGroup, renameGroup, recolorGroup
            addToGroup, removeFromGroup
            
            For createLog: newValue = log content, targetName = log title
            For editLog: targetName = log title to find, newValue = new content, secondaryValue = new title (optional)
            For deleteLog: targetName = log title
            For createEvent: newValue = event title, secondaryValue = date string
            For editEvent: targetName = event to find, newValue = new title, secondaryValue = new date (optional)
            For deleteEvent: targetName = event title
            For createNote: targetName = person name, newValue = note text
            For editNote: targetName = person name, newValue = new note text, secondaryValue = text to find in existing note
            For deleteNote: targetName = person name, secondaryValue = text to find (empty = delete all)
            For createGroup: newValue = group name, secondaryValue = color hex (optional, e.g. "4A9EDB")
            For deleteGroup: targetName = group name OR targetID = group UUID
            For renameGroup: targetName = current group name OR targetID = group UUID, newValue = new name
            For recolorGroup: targetName = group name OR targetID = group UUID, newValue = new color hex (e.g. "E05555")
            For addToGroup: targetName = group name, newValue = item name to add
            For removeFromGroup: targetName = group name, newValue = item name to remove
            
            Available colors for recolorGroup: 4A9EDB (blue), E05555 (red), 4CAF50 (green), F5A623 (orange), 8FA8A8 (gray), 9B59B6 (purple), E67E22 (dark orange), 1ABC9C (teal), E91E8C (pink), 3498DB (light blue)
            
            When the user is just asking a question or chatting, respond normally:
            {
              "message": "Your conversational reply here",
              "requiresConfirmation": false,
              "actions": []
            }
            
            ALWAYS respond with valid JSON only. Never include any text outside the JSON object.
            """
            
            var conversationMessages: [[String: String]] = []
            for msg in messages.dropLast() where !msg.isActionCard {
                conversationMessages.append([
                    "role": msg.isUser ? "user" : "assistant",
                    "content": msg.text
                ])
            }
            conversationMessages.append(["role": "user", "content": text])
            
            do {
                let body: [String: Any] = [
                    "model": "claude-sonnet-4-6",
                    "max_tokens": 2048,
                    "system": systemPrompt,
                    "messages": conversationMessages
                ]
                
                var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                let rawText = response.content.first?.text ?? "{}"
                
                var cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let jsonStart = cleaned.firstIndex(of: "{"),
                   let jsonEnd = cleaned.lastIndex(of: "}") {
                    cleaned = String(cleaned[jsonStart...jsonEnd])
                }
                
                if let jsonData = cleaned.data(using: .utf8),
                   let botResponse = try? JSONDecoder().decode(BotResponse.self, from: jsonData) {
                    await MainActor.run {
                        if botResponse.requiresConfirmation,
                           let actions = botResponse.actions,
                           !actions.isEmpty {
                            messages.append(ChatMessage(text: botResponse.message, isUser: false))
                            var card = ChatMessage(text: botResponse.message, isUser: false)
                            card.pendingActions = actions
                            card.isActionCard = true
                            messages.append(card)
                        } else {
                            messages.append(ChatMessage(text: botResponse.message, isUser: false))
                        }
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        messages.append(ChatMessage(text: rawText, isUser: false))
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(text: "Something went wrong. Please try again.", isUser: false))
                    isLoading = false
                }
            }
        }
    }
    
    func confirmActions(_ actions: [BotAction], messageID: UUID) {
        Task {
            let result = await BotActionExecutor.shared.execute(actions)
            await MainActor.run {
                messages.removeAll { $0.id == messageID }
                messages.append(ChatMessage(text: "Done! ✓ \(result)", isUser: false))
            }
        }
    }
    
    func cancelActions(messageID: UUID) {
        messages.removeAll { $0.id == messageID }
        messages.append(ChatMessage(text: "No problem, nothing was changed.", isUser: false))
    }
}

// MARK: - Action Confirmation Card
struct ActionConfirmationCard: View {
    let message: ChatMessage
    let actions: [BotAction]
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "8FA8A8").opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8FA8A8"))
                }
                Text("Proposed Changes")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "8FA8A8"))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(actions) { action in
                    HStack(spacing: 8) {
                        Image(systemName: actionIcon(action.type))
                            .font(.system(size: 11))
                            .foregroundColor(actionColor(action.type))
                            .frame(width: 16)
                        Text(action.description)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button(action: onConfirm) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Confirm")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "4CAF50").opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(Color(hex: "2C2C2E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "8FA8A8").opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
    
    func actionIcon(_ type: BotActionType) -> String {
        switch type {
        case .createLog, .editLog, .deleteLog: return "books.vertical"
        case .createEvent, .editEvent, .deleteEvent: return "calendar"
        case .createNote, .editNote, .deleteNote: return "note.text"
        case .createGroup, .deleteGroup, .renameGroup, .recolorGroup: return "folder"
        case .addToGroup, .removeFromGroup: return "arrow.right.circle"
        }
    }
    
    func actionColor(_ type: BotActionType) -> Color {
        switch type {
        case .createLog, .editLog, .deleteLog: return Color(hex: "4CAF50")
        case .createEvent, .editEvent, .deleteEvent: return Color(hex: "E05555")
        case .createNote, .editNote, .deleteNote: return Color(hex: "F5A623")
        case .createGroup, .deleteGroup, .renameGroup, .recolorGroup: return Color(hex: "9B59B6")
        case .addToGroup, .removeFromGroup: return Color(hex: "4A9EDB")
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 60) }
            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(Color(hex: "8FA8A8").opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8FA8A8"))
                }
            }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(message.isUser ? .white : .white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser
                            ? Color(hex: "8FA8A8").opacity(0.3)
                            : Color.white.opacity(0.07)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.25))
            }
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animate = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "8FA8A8").opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8FA8A8"))
            }
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 7, height: 7)
                        .offset(y: animate ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            Spacer(minLength: 60)
        }
        .onAppear { animate = true }
    }
}
