import SwiftUI
import StoreKit

struct JournAIPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var premium = PremiumManager.shared
    var onComplete: (() -> Void)? = nil
    
    let features: [(icon: String, color: String, title: String, subtitle: String)] = [
        ("wand.and.stars", "8FA8A8", "AI Categorization", "Automatically sort entries"),
        ("sparkles", "4A9EDB", "Journa AI Bot", "Chat with a personalized AI"),
        ("person.2.fill", "4CAF50", "Smart People Tracking", "Build rich profiles"),
        ("calendar", "E05555", "Auto Calendar", "Dates and events saved automatically"),
        ("folder.fill", "9B59B6", "Group Summaries", "AI-powered summaries of any group"),
        ("lock.shield.fill", "F5A623", "Unlock Everything", "Full access to all features")
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            // Gold radial glow
            RadialGradient(
                colors: [
                    Color(hex: "F5A623").opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // Crown icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700").opacity(0.2), Color(hex: "F5A623").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FFD700").opacity(0.4), Color(hex: "F5A623").opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "F5A623")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.bottom, 20)
                
                // Title
                VStack(spacing: 8) {
                    Text("JournAI")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "F5A623")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your journal, supercharged with AI.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 28)
                
                // Features
                VStack(spacing: 10) {
                    ForEach(features, id: \.title) { feature in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: feature.color).opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: feature.icon)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color(hex: feature.color))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(feature.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "FFD700"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Price + CTA
                VStack(spacing: 12) {
                    
                    // Price tag
                    if let product = premium.product {
                        Text("\(product.displayPrice) / month")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    // Purchase button
                    Button(action: {
                        Task {
                            await premium.purchase()
                            if premium.isPremium {
                                onComplete?()
                                dismiss()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if premium.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                Text("Start JournAI")
                                    .font(.system(size: 16, weight: .bold))
                            }
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
                    .disabled(premium.isLoading)
                    
                    // Restore
                    Button(action: {
                        Task {
                            await premium.restore()
                            if premium.isPremium {
                                onComplete?()
                                dismiss()
                            }
                        }
                    }) {
                        Text("Restore Purchase")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    
                    // Skip
                    Button(action: {
                        onComplete?()
                        dismiss()
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            Task { await premium.loadProduct() }
        }
    }
}
