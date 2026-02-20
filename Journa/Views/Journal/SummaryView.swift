import SwiftUI

struct SummaryView: View {
    @Binding var segments: [TaggedSegment]
    @Environment(\.dismiss) var dismiss
    var onLog: () -> Void
    
    var activeSegments: [TaggedSegment] {
        segments.filter { !$0.isRemoved }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Handle bar
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 16)
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CATEGORIZED")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(2)
                        Text("Review & Edit")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    HStack(spacing: 6) {
                        let dates = activeSegments.filter { $0.types.contains(.date) }.count
                        let people = activeSegments.filter { $0.types.contains(.person) }.count
                        let logs = activeSegments.filter { $0.types.contains(.log) }.count
                        
                        if dates > 0 {
                            CountBadge(count: dates, color: Color(hex: "E05555"))
                        }
                        if people > 0 {
                            CountBadge(count: people, color: Color(hex: "4A9EDB"))
                        }
                        if logs > 0 {
                            CountBadge(count: logs, color: Color(hex: "4CAF50"))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Segments
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach($segments) { $segment in
                            if !segment.isRemoved {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 12) {
                                        
                                        // Type indicator bars — one per type
                                        VStack(spacing: 3) {
                                            ForEach(segment.types, id: \.self) { type in
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(type.color)
                                                    .frame(width: 3, height: 16)
                                            }
                                        }
                                        .padding(.top, 4)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            TextEditor(text: $segment.text)
                                                .scrollContentBackground(.hidden)
                                                .background(Color.clear)
                                                .foregroundColor(.white)
                                                .font(.system(size: 15, weight: .medium))
                                                .lineSpacing(4)
                                                .frame(minHeight: 44)
                                            
                                            HStack {
                                                // Type labels
                                                HStack(spacing: 8) {
                                                    ForEach(segment.types, id: \.self) { type in
                                                        HStack(spacing: 4) {
                                                            Image(systemName: type.icon)
                                                                .font(.system(size: 11))
                                                            Text(type.destination.uppercased())
                                                                .font(.system(size: 11, weight: .bold))
                                                                .tracking(1)
                                                            
                                                            // Show name for person type
                                                            if type == .person {
                                                                let contacts = ContactsService.shared.people
                                                                let words = segment.text
                                                                    .components(separatedBy: .whitespaces)
                                                                    .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                                                                
                                                                let matchedName = words.first(where: { word in
                                                                    contacts.contains(where: {
                                                                        $0.name.lowercased().hasPrefix(word.lowercased()) &&
                                                                        word.count >= 2
                                                                    })
                                                                }) ?? ""
                                                                
                                                                if !matchedName.isEmpty {
                                                                    Text("· \(matchedName)")
                                                                        .font(.system(size: 11, weight: .bold))
                                                                        .tracking(1)
                                                                }
                                                            }
                                                        }
                                                        .foregroundColor(type.color.opacity(0.7))
                                                        
                                                        if type != segment.types.last {
                                                            Text("·")
                                                                .foregroundColor(.white.opacity(0.2))
                                                                .font(.system(size: 11))
                                                        }
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        segment.isRemoved = true
                                                    }
                                                }) {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundColor(.white.opacity(0.3))
                                                        .padding(6)
                                                        .background(Color.white.opacity(0.06))
                                                        .clipShape(Circle())
                                                }
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .background(segment.types.first?.color.opacity(0.07) ?? Color.white.opacity(0.07))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            
            // Floating bottom bar
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Redo")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                    }
                    
                    Button(action: { onLog() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Log Journal")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "8FA8A8"))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "1C1C1E").opacity(0), Color(hex: "1C1C1E")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

// MARK: - Count Badge
struct CountBadge: View {
    var count: Int
    var color: Color
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}
