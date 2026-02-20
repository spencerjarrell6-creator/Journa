import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var showingClearConfirm = false
    @State private var categorizeCalendar: Bool = Secrets.categorizeCalendar
    @State private var categorizeLogs: Bool = Secrets.categorizeLogs
    @State private var showPaywall = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var premium = PremiumManager.shared
    
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
                        Text("Settings")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Premium banner
                        if !premium.isPremium {
                            Button(action: { showPaywall = true }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: "F5A623").opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "F5A623"))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Upgrade to JournAI")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color(hex: "FFD700"), Color(hex: "F5A623")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        Text("Unlock AI categorization")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(14)
                                .background(Color(hex: "F5A623").opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "F5A623").opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            .padding(.top, 24)
                        } else {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: "F5A623").opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "F5A623"))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("JournAI Active")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "FFD700"), Color(hex: "F5A623")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    Text("All features unlocked")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "4CAF50"))
                            }
                            .padding(14)
                            .background(Color(hex: "F5A623").opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "F5A623").opacity(0.2), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .padding(.top, 24)
                        }
                        
                        Divider().background(Color.white.opacity(0.08))
                        
                        // API Key
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ANTHROPIC API KEY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            
                            SecureField("sk-ant-api03-...", text: $apiKey)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                            
                            Button(action: {
                                Secrets.anthropicAPIKey = apiKey
                                savedMessage = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: savedMessage ? "checkmark" : "key.fill")
                                        .font(.system(size: 13))
                                    Text(savedMessage ? "Saved!" : "Save Key")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(savedMessage ? Color(hex: "4CAF50") : Color(hex: "8FA8A8"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    savedMessage ?
                                    Color(hex: "4CAF50").opacity(0.12) :
                                    Color(hex: "8FA8A8").opacity(0.12)
                                )
                                .cornerRadius(8)
                            }
                            
                            Text("Stored securely on your device. Never shared.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.25))
                        }
                        
                        Divider().background(Color.white.opacity(0.08))
                        
                        // Categorization
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("CATEGORIZATION")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                                    .tracking(2)
                                
                                Spacer()
                                
                                if !premium.isPremium {
                                    Button(action: { showPaywall = true }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 10))
                                            Text("JournAI")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundColor(Color(hex: "F5A623"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(hex: "F5A623").opacity(0.12))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            
                            VStack(spacing: 8) {
                                ToggleRow(
                                    icon: "person.fill",
                                    label: "People",
                                    color: Color(hex: "4A9EDB"),
                                    isOn: $categorizePeople,
                                    locked: !premium.isPremium
                                ) { Secrets.categorizePeople = categorizePeople }
                                
                                ToggleRow(
                                    icon: "calendar",
                                    label: "Calendar",
                                    color: Color(hex: "E05555"),
                                    isOn: $categorizeCalendar,
                                    locked: !premium.isPremium
                                ) { Secrets.categorizeCalendar = categorizeCalendar }
                                
                                ToggleRow(
                                    icon: "book.fill",
                                    label: "Logs",
                                    color: Color(hex: "4CAF50"),
                                    isOn: $categorizeLogs,
                                    locked: !premium.isPremium
                                ) { Secrets.categorizeLogs = categorizeLogs }
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.08))
                        
                        // Data
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DATA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            
                            Button(action: { showingClearConfirm = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                    Text("Clear All Journal Data")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "FF6B6B"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(hex: "FF6B6B").opacity(0.08))
                                .cornerRadius(10)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.08))
                        
                        // About
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Journa")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("AI-powered CRM journal")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                Text("v1.0")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.3))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(6)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                            
                            Button(action: { hasSeenOnboarding = false }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14))
                                    Text("Replay Onboarding")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            JournAIPaywallView()
        }
        .confirmationDialog(
            "Clear all journal data?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All Data", role: .destructive) {
                if let context = LogStore.shared.modelContext {
                    try? context.delete(model: JournaLog.self)
                    try? context.delete(model: JournaEvent.self)
                    try? context.delete(model: JournaPerson.self)
                    try? context.delete(model: JournaGroup.self)
                    try? context.save()
                }
                LogStore.shared.fetch()
                CalendarService.shared.fetch()
                ContactsService.shared.fetch()
                GroupStore.shared.fetch()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all people notes, events, and logs. This cannot be undone.")
        }
    }
}

struct ToggleRow: View {
    var icon: String
    var label: String
    var color: Color
    @Binding var isOn: Bool
    var locked: Bool = false
    var onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(locked ? Color.white.opacity(0.05) : color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: locked ? "lock.fill" : icon)
                    .font(.system(size: 14))
                    .foregroundColor(locked ? .white.opacity(0.2) : color)
            }
            
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(locked ? .white.opacity(0.3) : .white)
            
            Spacer()
            
            if locked {
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "F5A623"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(hex: "F5A623").opacity(0.12))
                    .cornerRadius(5)
            } else {
                Toggle("", isOn: $isOn)
                    .tint(color)
                    .onChange(of: isOn) { onChange() }
            }
        }
        .padding(12)
        .background(Color.white.opacity(locked ? 0.02 : 0.04))
        .cornerRadius(10)
    }
}
