import SwiftUI

struct GroupsView: View {
    @ObservedObject var groupStore = GroupStore.shared
    @State private var showingCreate = false
    @State private var searchText = ""
    @State private var editingGroup: JournaGroup? = nil
    @StateObject private var premium = PremiumManager.shared
    
    var filteredGroups: [JournaGroup] {
        if searchText.isEmpty { return groupStore.groups }
        return groupStore.groups.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
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
                            Text("Groups")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        Button(action: { showingCreate = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 13))
                                Text("New Group")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.3))
                            .font(.system(size: 14))
                        TextField("Search groups...", text: $searchText)
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
                    
                    if groupStore.groups.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No groups yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Create a group to organize your\nlogs, people, and events.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.2))
                                .multilineTextAlignment(.center)
                            Button(action: { showingCreate = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 13))
                                    Text("Create Group")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        Spacer()
                    } else if filteredGroups.isEmpty {
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
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(filteredGroups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupCard(group: group)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(action: { editingGroup = group }) {
                                            Label("Edit Name & Color", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            groupStore.remove(group.id)
                                        } label: {
                                            Label("Delete Group", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateGroupView()
            }
            .sheet(item: $editingGroup) { group in
                EditGroupView(group: group)
            }
        }
    }
}

// MARK: - Group Card
struct GroupCard: View {
    var group: JournaGroup
    
    var itemCount: Int {
        group.logIDs.count + group.eventIDs.count + group.personIDs.count + group.noteIDs.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(group.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 18))
                        .foregroundColor(group.color)
                }
                Spacer()
                Text("\(itemCount)")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(group.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(itemCount == 1 ? "1 item" : "\(itemCount) items")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            HStack(spacing: 4) {
                if !group.logIDs.isEmpty {
                    MiniPill(icon: "book.fill", color: Color(hex: "4CAF50"))
                }
                if !group.eventIDs.isEmpty {
                    MiniPill(icon: "calendar", color: Color(hex: "E05555"))
                }
                if !group.personIDs.isEmpty {
                    MiniPill(icon: "person.fill", color: Color(hex: "4A9EDB"))
                }
                if !group.noteIDs.isEmpty {
                    MiniPill(icon: "note.text", color: Color(hex: "F5A623"))
                }
            }
        }
        .padding(16)
        .background(group.color.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(group.color.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

struct MiniPill: View {
    var icon: String
    var color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 9))
            .foregroundColor(color)
            .padding(5)
            .background(color.opacity(0.15))
            .cornerRadius(5)
    }
}

// MARK: - Edit Group View
struct EditGroupView: View {
    var group: JournaGroup
    @Environment(\.dismiss) var dismiss
    @ObservedObject var groupStore = GroupStore.shared
    @State private var name: String = ""
    @State private var selectedColor: String = ""
    
    let colors = JournaGroup.accentColors
    
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
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("Edit Group")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            groupStore.renameGroup(group.id, to: trimmed)
                        }
                        groupStore.recolorGroup(group.id, colorHex: selectedColor)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: selectedColor))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider().background(Color.white.opacity(0.08))
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: selectedColor).opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "folder.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: selectedColor))
                        }
                        .padding(.top, 20)
                        
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GROUP NAME")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            
                            TextField("Group name...", text: $name)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COLOR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(colors, id: \.self) { hex in
                                    Button(action: { selectedColor = hex }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 44, height: 44)
                                            if selectedColor == hex {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 3)
                                                    .frame(width: 44, height: 44)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Delete button
                        Button(action: {
                            groupStore.remove(group.id)
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                Text("Delete Group")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "FF6B6B"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "FF6B6B").opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            name = group.name
            selectedColor = group.colorHex
        }
    }
}
