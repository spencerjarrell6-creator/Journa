import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @State private var symbolOpacity = 0.0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        if isActive {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        } else {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Image("journa")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
                    opacity = 1.0
                    scale = 1.0
                }
                withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
                    symbolOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        opacity = 0.0
                        symbolOpacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isActive = true
                    }
                }
            }
        }
    }
}
