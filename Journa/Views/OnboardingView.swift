import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var showPaywall = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "pencil.and.scribble",
            title: "Welcome to Journa",
            subtitle: "Your personal journal that thinks with you.",
            color: "8FA8A8"
        ),
        OnboardingPage(
            icon: "text.alignleft",
            title: "Write Anything",
            subtitle: "Type or dictate your thoughts. Journa listens without judgment.",
            color: "4A9EDB"
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "Track People",
            subtitle: "Journa automatically picks up on people you mention and builds a profile over time.",
            color: "4CAF50"
        ),
        OnboardingPage(
            icon: "calendar",
            title: "Smart Calendar",
            subtitle: "Dates and events in your entries are automatically saved to your calendar.",
            color: "E05555"
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Journa AI",
            subtitle: "Chat with an AI that knows your logs, people, calendar, and groups. Ask questions, find patterns, get insights — all from your own data.",
            color: "F5A623"
        ),
        OnboardingPage(
            icon: "folder.fill",
            title: "Groups",
            subtitle: "Organize logs, events, people, and notes into groups. Premium users can get AI summaries of each group.",
            color: "9B59B6"
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Private by Default",
            subtitle: "Your journal stays on your device. Lock individual profiles with Face ID.",
            color: "8FA8A8"
        )
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ?
                                  Color(hex: pages[index].color) :
                                  Color.white.opacity(0.2))
                            .frame(width: currentPage == index ? 20 : 6, height: 6)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Buttons
                VStack(spacing: 12) {
                    if currentPage == pages.count - 1 {
                        Button(action: { showPaywall = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                Text("Unlock JournAI")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "F5A623")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                        }
                        
                        Button(action: {
                            hasSeenOnboarding = true
                        }) {
                            Text("Continue without premium")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    } else {
                        Button(action: {
                            withAnimation { currentPage += 1 }
                        }) {
                            Text("Continue")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: pages[currentPage].color).opacity(0.8))
                                .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showPaywall) {
            JournAIPaywallView(onComplete: {
                hasSeenOnboarding = true
            })
        }
    }
}

// MARK: - Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: String
}

// MARK: - Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(hex: page.color).opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52))
                    .foregroundColor(Color(hex: page.color))
            }
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}
