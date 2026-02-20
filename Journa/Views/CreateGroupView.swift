import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var selectedColor = JournaGroup.randomColor()
    @ObservedObject var groupStore = GroupStore.shared
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: selectedColor).opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: selectedColor))
                }
                .padding(.bottom, 20)
                
                Text(groupName.isEmpty ? "New Group" : groupName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 32)
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GROUP NAME")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(2)
                        
                        TextField("e.g. Work Project, Trip Planning...", text: $groupName)
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                    }
                    
                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACCENT COLOR")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(2)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(JournaGroup.accentColors, id: \.self) { hex in
                                Button(action: { selectedColor = hex }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 40, height: 40)
                                        if selectedColor == hex {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .frame(width: 46, height: 46)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Create button
                Button(action: {
                    guard !groupName.isEmpty else { return }
                    let group = groupStore.createGroup(name: groupName)
                    if let i = groupStore.groups.firstIndex(where: { $0.id == group.id }) {
                        groupStore.groups[i].colorHex = selectedColor
                    }
                    dismiss()
                }) {
                    Text("Create Group")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(groupName.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(groupName.isEmpty ?
                            Color.white.opacity(0.06) :
                            Color(hex: selectedColor).opacity(0.8))
                        .cornerRadius(14)
                }
                .disabled(groupName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}
