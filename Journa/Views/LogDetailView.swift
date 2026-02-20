import SwiftUI

struct LogDetailView: View {
    var log: JournaLog
    @ObservedObject var logStore = LogStore.shared
    @State private var editedText: String = ""
    @State private var isEditing: Bool = false
    @State private var isEditingTitle: Bool = false
    @State private var editedTitle: String = ""
    @State private var showRecategorizeWarning: Bool = false
    @State private var isRecategorizing: Bool = false
    @State private var currentSegments: [TaggedSegment] = []
    @StateObject private var premium = PremiumManager.shared
    
    var currentLog: JournaLog {
        logStore.logs.first(where: { $0.id == log.id }) ?? log
    }
    
    var activeSegments: [TaggedSegment] {
        currentSegments.filter { !$0.isRemoved }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Date header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentLog.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()).uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(2)
                        
                        HStack(spacing: 8) {
                            if isEditingTitle {
                                TextField("Title...", text: $editedTitle)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .onSubmit { saveTitle() }
                            } else {
                                Text(currentLog.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineSpacing(4)
                            }
                            
                            Button(action: {
                                if isEditingTitle {
                                    saveTitle()
                                } else {
                                    editedTitle = currentLog.title
                                    isEditingTitle = true
                                }
                            }) {
                                Image(systemName: isEditingTitle ? "checkmark.circle.fill" : "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(isEditingTitle ?
                                        Color(hex: "4CAF50") : .white.opacity(0.3))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // Entry section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("ENTRY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                if isEditing {
                                    // Save edited text
                                    if let index = logStore.logs.firstIndex(where: { $0.id == log.id }) {
                                        logStore.logs[index].rawText = editedText
                                    }
                                    isEditing = false
                                } else {
                                    editedText = currentLog.rawText
                                    isEditing = true
                                }
                            }) {
                                Text(isEditing ? "Save" : "Edit")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(isEditing ? Color(hex: "4CAF50") : Color(hex: "8FA8A8"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isEditing ?
                                        Color(hex: "4CAF50").opacity(0.12) :
                                        Color(hex: "8FA8A8").opacity(0.12))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        if isEditing {
                            TextEditor(text: $editedText)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .lineSpacing(6)
                                .frame(minHeight: 200)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "8FA8A8").opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                        } else {
                            Text(currentLog.rawText)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(6)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // Categorized segments
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("CATEGORIZED")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            
                            Spacer()
                            
                            if premium.isPremium {
                                Button(action: {
                                    showRecategorizeWarning = true
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 11))
                                        Text("Re-categorize")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(Color(hex: "8FA8A8"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "8FA8A8").opacity(0.12))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        if isRecategorizing {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(Color(hex: "8FA8A8"))
                                Text("Re-categorizing...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 20)
                        } else if activeSegments.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.15))
                                Text("No categorizations")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.25))
                                
                                if premium.isPremium {
                                    Button(action: { showRecategorizeWarning = true }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 11))
                                            Text("Categorize Now")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(Color(hex: "8FA8A8"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "8FA8A8").opacity(0.12))
                                        .cornerRadius(8)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(currentSegments.enumerated()), id: \.element.id) { index, segment in
                                    if !segment.isRemoved {
                                        SegmentRow(
                                            segment: segment,
                                            logID: log.id,
                                            onRemove: {
                                                currentSegments[index].isRemoved = true
                                                if let logIndex = logStore.logs.firstIndex(where: { $0.id == log.id }) {
                                                    logStore.logs[logIndex].segments = currentSegments
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentSegments = currentLog.segments
            editedTitle = currentLog.title
            editedText = currentLog.rawText
        }
        .confirmationDialog(
            "Re-categorize this entry?",
            isPresented: $showRecategorizeWarning,
            titleVisibility: .visible
        ) {
            Button("Re-categorize", role: .destructive) {
                Task { await recategorize() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All previous categorizations will be removed and replaced. This cannot be undone.")
        }
    }
    
    func saveTitle() {
        if let index = logStore.logs.firstIndex(where: { $0.id == log.id }) {
            logStore.logs[index].title = editedTitle
        }
        isEditingTitle = false
    }
    
    func recategorize() async {
        isRecategorizing = true
        // Always use the latest saved text
        let textToUse = isEditing ? editedText : currentLog.rawText
        do {
            let newSegments = try await AIService.shared.summarizeJournal(text: textToUse)
            await MainActor.run {
                currentSegments = newSegments
                if let index = logStore.logs.firstIndex(where: { $0.id == log.id }) {
                    logStore.logs[index].segments = newSegments
                    // Also update rawText if we were editing
                    if isEditing {
                        logStore.logs[index].rawText = editedText
                        isEditing = false
                    }
                }
            }
        } catch {
            print("Recategorize failed: \(error)")
        }
        isRecategorizing = false
    }
}

// MARK: - Segment Row
struct SegmentRow: View {
    var segment: TaggedSegment
    var logID: UUID
    var onRemove: () -> Void
    @State private var showRemoveConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 3) {
                    ForEach(segment.types, id: \.self) { type in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(type.color)
                            .frame(width: 3, height: 14)
                    }
                }
                .padding(.top, 3)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(segment.text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                    
                    HStack(spacing: 8) {
                        ForEach(segment.types, id: \.self) { type in
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 10))
                                Text(type.destination.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                            }
                            .foregroundColor(type.color.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        if segment.types.contains(.person),
                           let name = segment.contactName {
                            NavigationLink(destination: SourcePersonView(personName: name, logID: logID)) {
                                HStack(spacing: 3) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 9))
                                    Text("View in Profile")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "4A9EDB").opacity(0.8))
                            }
                        }
                        
                        Button(action: { showRemoveConfirm = true }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(5)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(segment.types.first?.color.opacity(0.07) ?? Color.white.opacity(0.07))
        .cornerRadius(12)
        .confirmationDialog(
            "Remove this categorization?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { onRemove() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the categorization but keep the original log text.")
        }
    }
}

// MARK: - Source Person View
struct SourcePersonView: View {
    var personName: String
    var logID: UUID
    
    var person: JournaPerson? {
        ContactsService.shared.people.first {
            $0.name.lowercased() == personName.lowercased() ||
            $0.name.lowercased().hasPrefix(personName.lowercased())
        }
    }
    
    var body: some View {
        if let person = person {
            PersonDetailView(person: person)
        } else {
            ZStack {
                Color(hex: "1C1C1E").ignoresSafeArea()
                Text("Person not found")
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}
