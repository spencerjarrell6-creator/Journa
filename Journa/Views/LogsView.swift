import SwiftUI

struct LogsView: View {
    @ObservedObject var logStore = LogStore.shared
    @State private var searchText = ""
    
    var sortedLogs: [JournaLog] {
        logStore.logs.sorted { a, b in
            if a.isPinned == b.isPinned { return a.date > b.date }
            return a.isPinned && !b.isPinned
        }
    }
    
    var filteredLogs: [JournaLog] {
        if searchText.isEmpty { return sortedLogs }
        return sortedLogs.filter { log in
            log.title.lowercased().contains(searchText.lowercased()) ||
            log.rawText.lowercased().contains(searchText.lowercased())
        }
    }
    
    var groupedLogs: [(String, [JournaLog])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        if !searchText.isEmpty {
            return [("RESULTS", filteredLogs)]
        }
        
        let pinned = filteredLogs.filter { $0.isPinned }
        let unpinned = filteredLogs.filter { !$0.isPinned }
        
        var result: [(String, [JournaLog])] = []
        
        if !pinned.isEmpty {
            result.append(("PINNED", pinned))
        }
        
        let groups = Dictionary(grouping: unpinned) {
            formatter.string(from: $0.date)
        }
        let sorted = groups.sorted { a, b in
            let dateA = unpinned.first(where: { formatter.string(from: $0.date) == a.key })?.date ?? Date()
            let dateB = unpinned.first(where: { formatter.string(from: $0.date) == b.key })?.date ?? Date()
            return dateA > dateB
        }
        result += sorted
        
        return result
    }
    
    var body: some View {
        NavigationStack {
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
                            Text("Your Logs")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        Text("\(logStore.logs.count) entries")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
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
                        TextField("Search logs...", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
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
                    
                    if logStore.logs.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "books.vertical")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No logs yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Categorize a journal entry\nto see it here.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.2))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else if filteredLogs.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No results for \"\(searchText)\"")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(groupedLogs, id: \.0) { month, logs in
                                Section {
                                    ForEach(logs) { log in
                                        NavigationLink(destination: LogDetailView(log: log)) {
                                            HStack(alignment: .top, spacing: 16) {
                                                
                                                // Date badge
                                                VStack(spacing: 2) {
                                                    Text(log.date.formatted(.dateTime.day()))
                                                        .font(.system(size: 22, weight: .black))
                                                        .foregroundColor(.white)
                                                    Text(log.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.white.opacity(0.4))
                                                        .tracking(1)
                                                }
                                                .frame(width: 40)
                                                
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.08))
                                                    .frame(width: 1)
                                                
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack(spacing: 6) {
                                                        HighlightedText(
                                                            text: log.title,
                                                            query: searchText,
                                                            baseColor: .white
                                                        )
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .lineLimit(2)
                                                        
                                                        if log.isPinned {
                                                            Image(systemName: "pin.fill")
                                                                .font(.system(size: 10))
                                                                .foregroundColor(Color(hex: "8FA8A8"))
                                                                .rotationEffect(.degrees(45))
                                                        }
                                                    }
                                                    
                                                    // Show matching snippet from rawText
                                                    if !searchText.isEmpty,
                                                       let snippet = extractSnippet(from: log.rawText, query: searchText) {
                                                        HighlightedText(
                                                            text: snippet,
                                                            query: searchText,
                                                            baseColor: .white.opacity(0.4)
                                                        )
                                                        .font(.system(size: 12))
                                                        .lineLimit(2)
                                                    }
                                                    
                                                    HStack(spacing: 6) {
                                                        // Import source badge
                                                        if let source = log.importSource,
                                                           let importType = ImportSource(rawValue: source) {
                                                            HStack(spacing: 4) {
                                                                Image(systemName: importType.icon)
                                                                    .font(.system(size: 9))
                                                                    .foregroundColor(importType.color)
                                                                if let contact = log.importContact {
                                                                    Text(contact)
                                                                        .font(.system(size: 10, weight: .semibold))
                                                                        .foregroundColor(importType.color)
                                                                }
                                                            }
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 3)
                                                            .background(importType.color.opacity(0.12))
                                                            .cornerRadius(5)
                                                        }
                                                        
                                                        let hasDate = log.segments.contains { $0.types.contains(.date) }
                                                        let hasPerson = log.segments.contains { $0.types.contains(.person) }
                                                        let hasLog = log.segments.contains { $0.types.contains(.log) }
                                                        
                                                        if hasDate {
                                                            TypePill(icon: "calendar", color: Color(hex: "E05555"))
                                                        }
                                                        if hasPerson {
                                                            TypePill(icon: "person.fill", color: Color(hex: "4A9EDB"))
                                                        }
                                                        if hasLog {
                                                            TypePill(icon: "book.fill", color: Color(hex: "4CAF50"))
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Text(log.date.formatted(.dateTime.hour().minute()))
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.white.opacity(0.3))
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .listRowBackground(Color.white.opacity(0.04))
                                        .listRowSeparatorTint(Color.white.opacity(0.06))
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                if let index = logStore.logs.firstIndex(where: { $0.id == log.id }) {
                                                    logStore.logs[index].isPinned.toggle()
                                                    logStore.save()
                                                }
                                            } label: {
                                                Label(log.isPinned ? "Unpin" : "Pin", systemImage: log.isPinned ? "pin.slash" : "pin.fill")
                                            }
                                            .tint(Color(hex: "8FA8A8"))
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                logStore.delete(log)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                } header: {
                                    Text(month)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(month == "PINNED" || month == "RESULTS" ? Color(hex: "8FA8A8") : .white.opacity(0.3))
                                        .tracking(2)
                                        .textCase(nil)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
        }
    }
    
    func extractSnippet(from text: String, query: String) -> String? {
        let lower = text.lowercased()
        let lowerQuery = query.lowercased()
        guard let range = lower.range(of: lowerQuery) else { return nil }
        let index = lower.distance(from: lower.startIndex, to: range.lowerBound)
        let start = max(0, index - 30)
        let startIndex = text.index(text.startIndex, offsetBy: start)
        let end = min(text.count, index + query.count + 60)
        let endIndex = text.index(text.startIndex, offsetBy: end)
        let snippet = String(text[startIndex..<endIndex])
        return (start > 0 ? "..." : "") + snippet + (end < text.count ? "..." : "")
    }
}
