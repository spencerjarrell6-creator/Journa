import SwiftUI
import Contacts
import Speech

struct ConflictData: Identifiable {
    let id = UUID()
    let matches: [JournaPerson]
}

enum ImportSource: String, CaseIterable {
    case instagram = "Instagram"
    case messages = "Messages"
    case whatsapp = "WhatsApp"
    case twitter = "Twitter"
    case email = "Email"
    
    var icon: String {
        switch self {
        case .instagram: return "camera.filters"
        case .messages: return "message.fill"
        case .whatsapp: return "phone.fill"
        case .twitter: return "bird"
        case .email: return "envelope.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .instagram: return Color(hex: "E1306C")
        case .messages: return Color(hex: "4CAF50")
        case .whatsapp: return Color(hex: "25D366")
        case .twitter: return Color(hex: "1DA1F2")
        case .email: return Color(hex: "8FA8A8")
        }
    }
}

struct JournalView: View {
    @State private var journalText: String = ""
    @State private var isListening: Bool = false
    @State private var isLoading: Bool = false
    @State private var segments: [TaggedSegment] = []
    @State private var showSummary: Bool = false
    @State private var errorMessage: String? = nil
    @State private var conflictData: ConflictData? = nil
    @State private var pendingSegments: [(segment: TaggedSegment, matches: [JournaPerson])] = []
    @State private var showPaywall: Bool = false
    @State private var showLoggedConfirm: Bool = false
    @State private var savedLogID: UUID? = nil
    @State private var showSettings: Bool = false
    @State private var showBot: Bool = false
    @State private var showNameLogPopup: Bool = false
    @State private var pendingLogText: String = ""
    @State private var quickLogName: String = ""
    @StateObject private var premium = PremiumManager.shared
    
    // Import mode
    @State private var isImportMode: Bool = false
    @State private var selectedImportSource: ImportSource? = nil
    @State private var selectedImportContact: JournaPerson? = nil
    @State private var showSourcePicker: Bool = false
    @State private var showContactPicker: Bool = false
    @State private var importPOVIsMe: Bool = true
    
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
                        Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Text(TimeZone.current.abbreviation() ?? "")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Import mode bar
                if isImportMode {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            // Source picker
                            Button(action: { showSourcePicker = true }) {
                                HStack(spacing: 6) {
                                    if let source = selectedImportSource {
                                        Image(systemName: source.icon)
                                            .font(.system(size: 12))
                                            .foregroundColor(source.color)
                                        Text(source.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.4))
                                        Text("From where?")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedImportSource != nil ?
                                    selectedImportSource!.color.opacity(0.15) :
                                    Color.white.opacity(0.06))
                                .cornerRadius(8)
                            }
                            
                            // Contact picker
                            Button(action: { showContactPicker = true }) {
                                HStack(spacing: 6) {
                                    if let contact = selectedImportContact {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "4A9EDB"))
                                        Text(contact.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.4))
                                        Text("From who?")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedImportContact != nil ?
                                    Color(hex: "4A9EDB").opacity(0.15) :
                                    Color.white.opacity(0.06))
                                .cornerRadius(8)
                            }
                            
                            // POV toggle
                            if selectedImportContact != nil {
                                Button(action: { importPOVIsMe.toggle() }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: importPOVIsMe ? "person.crop.circle" : "person.crop.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(importPOVIsMe ? Color(hex: "4CAF50") : Color(hex: "F5A623"))
                                        Text(importPOVIsMe ? "My POV" : "\(selectedImportContact!.name)'s POV")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(importPOVIsMe ? Color(hex: "4CAF50") : Color(hex: "F5A623"))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(importPOVIsMe ?
                                        Color(hex: "4CAF50").opacity(0.12) :
                                        Color(hex: "F5A623").opacity(0.12))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        if selectedImportContact != nil {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.3))
                                Text(importPOVIsMe ?
                                    "My POV — AI extracts what \(selectedImportContact!.name) said to me." :
                                    "\(selectedImportContact!.name)'s POV — AI reads everything as \(selectedImportContact!.name)'s words.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Journal text input
                ZStack(alignment: .topLeading) {
                    if journalText.isEmpty {
                        Text(isImportMode ? "Paste conversation here..." : "Write anything...")
                            .foregroundColor(Color.white.opacity(0.2))
                            .font(.system(size: 18, weight: .regular))
                            .padding(.top, 20)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $journalText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .regular))
                        .lineSpacing(6)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Status messages
                if showLoggedConfirm {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "4CAF50"))
                        Text("Saved to logs")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.opacity)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
                
                // Bottom area
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // Mode toggle row — premium only
                    if premium.isPremium {
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    isImportMode.toggle()
                                    if !isImportMode {
                                        selectedImportSource = nil
                                        selectedImportContact = nil
                                        importPOVIsMe = true
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isImportMode ? "square.and.arrow.down" : "pencil.line")
                                        .font(.system(size: 12))
                                    Text(isImportMode ? "Import Mode" : "Journaling Mode")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(isImportMode ? Color(hex: "F5A623") : .white.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isImportMode ?
                                    Color(hex: "F5A623").opacity(0.12) :
                                    Color.white.opacity(0.06))
                                .cornerRadius(10)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                    }
                    
                    // Quick log row
                    HStack {
                        Spacer()
                        Button(action: {
                            guard !journalText.isEmpty else { return }
                            pendingLogText = journalText
                            quickLogName = ""
                            withAnimation(.spring(response: 0.35)) {
                                showNameLogPopup = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 13))
                                Text("Quick Log")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(journalText.isEmpty ?
                                             .white.opacity(0.2) :
                                             .white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(journalText.isEmpty ?
                                        Color.white.opacity(0.03) :
                                        Color.white.opacity(0.07))
                            .cornerRadius(10)
                        }
                        .disabled(journalText.isEmpty)
                        Spacer()
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    
                    // Main action row
                    HStack(alignment: .center, spacing: 12) {
                        
                        // Mic button
                        Button(action: {
                            if VoiceService.shared.isListening {
                                VoiceService.shared.stopListening()
                                isListening = false
                            } else {
                                isListening = true
                                let existingText = journalText
                                Task {
                                    await VoiceService.shared.startListening { text in
                                        if existingText.isEmpty {
                                            journalText = text
                                        } else {
                                            journalText = existingText + " " + text
                                        }
                                    }
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isListening ?
                                          Color(hex: "FF6B6B").opacity(0.15) :
                                          Color.white.opacity(0.06))
                                    .frame(width: 44, height: 44)
                                Image(systemName: isListening ? "mic.fill" : "mic")
                                    .font(.system(size: 18))
                                    .foregroundColor(isListening ?
                                                     Color(hex: "FF6B6B") :
                                                     Color.white.opacity(0.5))
                            }
                        }
                        
                        Spacer()
                        
                        // AI / Crown button
                        Button(action: {
                            if premium.isPremium {
                                showBot = true
                            } else {
                                showPaywall = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        premium.isPremium ?
                                        LinearGradient(
                                            colors: [Color(hex: "8FA8A8"), Color(hex: "4A9EDB")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color(hex: "F5A623"), Color(hex: "FFD700")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .shadow(
                                        color: premium.isPremium ?
                                            Color(hex: "8FA8A8").opacity(0.3) :
                                            Color(hex: "F5A623").opacity(0.3),
                                        radius: 8, x: 0, y: 3
                                    )
                                Image(systemName: premium.isPremium ? "sparkles" : "crown.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Categorize — premium only
                        if premium.isPremium {
                            Button(action: {
                                Task { await summarize() }
                            }) {
                                ZStack {
                                    if isLoading {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "8FA8A8").opacity(0.15))
                                            .frame(width: 150, height: 44)
                                        ProgressView()
                                            .tint(Color(hex: "8FA8A8"))
                                    } else {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(journalText.isEmpty ?
                                                  Color.white.opacity(0.05) :
                                                  Color(hex: "8FA8A8").opacity(0.15))
                                            .frame(width: 150, height: 44)
                                        Text("CATEGORIZE")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(journalText.isEmpty ?
                                                             Color.white.opacity(0.2) :
                                                             Color(hex: "8FA8A8"))
                                            .tracking(1.5)
                                    }
                                }
                            }
                            .disabled(journalText.isEmpty || isLoading)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            
            // Name log popup overlay
            if showNameLogPopup {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35)) {
                            showNameLogPopup = false
                        }
                    }
                
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Text("Name this log")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                            Text("Give it a title or save as is")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.top, 20)
                        
                        TextField("Log title...", text: $quickLogName)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.spring(response: 0.35)) {
                                    showNameLogPopup = false
                                }
                                pendingLogText = ""
                                quickLogName = ""
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { saveQuickLog() }) {
                                Text("Save")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "4CAF50").opacity(0.8))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Source picker overlay
            if showSourcePicker {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { showSourcePicker = false }
                
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Text("Import From")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                        
                        ForEach(ImportSource.allCases, id: \.self) { source in
                            Button(action: {
                                selectedImportSource = source
                                showSourcePicker = false
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(source.color.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: source.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(source.color)
                                    }
                                    Text(source.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedImportSource == source {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(source.color)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            Divider().background(Color.white.opacity(0.06))
                        }
                        
                        Button(action: { showSourcePicker = false }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Contact picker overlay
            if showContactPicker {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { showContactPicker = false }
                
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Text("From Who?")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(ContactsService.shared.people.filter { $0.isActive }) { person in
                                    Button(action: {
                                        selectedImportContact = person
                                        showContactPicker = false
                                    }) {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: "4A9EDB").opacity(0.15))
                                                    .frame(width: 36, height: 36)
                                                Text(String(person.name.prefix(1)))
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(Color(hex: "4A9EDB"))
                                            }
                                            Text(person.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            Spacer()
                                            if selectedImportContact?.id == person.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(hex: "4A9EDB"))
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                    }
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        
                        Button(action: { showContactPicker = false }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: showNameLogPopup)
        .animation(.spring(response: 0.35), value: showSourcePicker)
        .animation(.spring(response: 0.35), value: showContactPicker)
        .animation(.spring(response: 0.3), value: isImportMode)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showSummary) {
            SummaryView(
                segments: $segments,
                onLog: {
                    logJournal()
                    showSummary = false
                }
            )
        }
        .sheet(isPresented: $showPaywall) {
            JournAIPaywallView()
        }
        .fullScreenCover(isPresented: $showBot) {
            AIBotView()
        }
        .sheet(item: $conflictData) { data in
            ZStack {
                Color(hex: "1C1C1E").ignoresSafeArea()
                VStack(alignment: .center, spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    Text("Who did you mean?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    Text("Multiple contacts match. Select one to continue.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                    if let segmentText = pendingSegments.first?.segment.text {
                        Text("\"\(segmentText)\"")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)
                    }
                    VStack(spacing: 12) {
                        ForEach(data.matches) { person in
                            Button {
                                Task { await resolveConflict(person: person) }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "4A9EDB").opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Text(String(person.name.prefix(1)).uppercased())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color(hex: "4A9EDB"))
                                    }
                                    Text(person.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .interactiveDismissDisabled(true)
        }
    }
    
    func saveQuickLog() {
        let log = LogStore.shared.saveLog(rawText: pendingLogText, segments: [])
        let title = quickLogName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty {
            if let index = LogStore.shared.logs.firstIndex(where: { $0.id == log.id }) {
                LogStore.shared.logs[index].title = title
            }
        }
        savedLogID = log.id
        withAnimation {
            journalText = ""
            showNameLogPopup = false
            showLoggedConfirm = true
        }
        pendingLogText = ""
        quickLogName = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showLoggedConfirm = false }
        }
    }
    
    func summarize() async {
        guard !journalText.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            if isImportMode {
                segments = try await AIService.shared.summarizeImport(
                    text: journalText,
                    source: selectedImportSource?.rawValue,
                    fromContact: selectedImportContact?.name,
                    povIsMe: importPOVIsMe
                )
            } else {
                segments = try await AIService.shared.summarizeJournal(text: journalText)
            }
            await filterUnmatchedPeople()
            showSummary = true
        } catch {
            errorMessage = "Could not categorize. Check your API key."
        }
        isLoading = false
    }
    
    func filterUnmatchedPeople() async {
        let ownerNames = ContactsService.shared.getDeviceOwnerName()
        var filtered = segments
        
        for i in segments.indices {
            if segments[i].types.contains(.person) {
                let words = segments[i].text.lowercased()
                    .components(separatedBy: .whitespacesAndNewlines)
                    .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                let refersToOwner = ownerNames.contains { name in
                    words.contains(name.lowercased())
                }
                if refersToOwner {
                    filtered[i].isRemoved = true
                }
            }
        }
        await MainActor.run { segments = filtered }
    }
    
    func logJournal() {
        let savedLog = LogStore.shared.saveLog(rawText: journalText, segments: segments)
        savedLogID = savedLog.id
        let active = segments.filter { !$0.isRemoved }
        
        Task {
            for segment in active {
                switch segment.type {
                case .date:
                    let date = CalendarService.shared.parseDate(from: segment.text)
                    await CalendarService.shared.saveEvent(title: segment.text, date: date, type: .date)
                case .log:
                    await CalendarService.shared.saveEvent(title: segment.text, date: Date(), type: .log)
                case .person:
                    let searchName = segment.contactName ?? segment.text
                    let matches = await ContactsService.shared.matchContacts(for: searchName)
                    if matches.isEmpty { continue }
                    if matches.count == 1 {
                        let person = matches[0]
                        await ContactsService.shared.savePerson(
                            name: person.name,
                            notes: segment.text,
                            contactID: person.contactID,
                            logID: savedLog.id
                        )
                    } else {
                        await MainActor.run {
                            pendingSegments.append((segment: segment, matches: matches))
                        }
                    }
                }
            }
            
            await MainActor.run {
                if pendingSegments.isEmpty {
                    journalText = ""
                    segments = []
                } else {
                    conflictData = ConflictData(matches: pendingSegments[0].matches)
                }
            }
        }
    }
    
    func resolveConflict(person: JournaPerson) async {
        guard !pendingSegments.isEmpty else { return }
        let current = pendingSegments[0]
        await ContactsService.shared.savePerson(
            name: person.name,
            notes: current.segment.text,
            contactID: person.contactID,
            logID: savedLogID
        )
        await MainActor.run {
            pendingSegments.removeFirst()
            if pendingSegments.isEmpty {
                conflictData = nil
                journalText = ""
                segments = []
            } else {
                conflictData = ConflictData(matches: pendingSegments[0].matches)
            }
        }
    }
}
