import SwiftUI
import LocalAuthentication

struct PersonDetailView: View {
    var person: JournaPerson
    @State private var showingAddNote = false
    @State private var isUnlocked = false
    @State private var isLocked: Bool = false
    @State private var authError: String? = nil
    
    var lockKey: String { "locked_\(person.id)" }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.name.uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "4A9EDB"))
                        Text("\(person.notes.count) notes")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    
                    Spacer()
                    
                    // Lock toggle
                    Button(action: toggleLock) {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open")
                            .font(.system(size: 16))
                            .foregroundColor(isLocked ? Color(hex: "E05555") : .white.opacity(0.3))
                            .padding(10)
                            .background(isLocked ?
                                Color(hex: "E05555").opacity(0.12) :
                                Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                if isLocked && !isUnlocked {
                    // Locked state
                    Spacer()
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E05555").opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "E05555").opacity(0.7))
                        }
                        
                        Text("Notes are locked")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if let error = authError {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "FF6B6B"))
                        }
                        
                        Button(action: { authenticate() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 15))
                                Text("Unlock Notes")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color(hex: "4A9EDB"))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                    
                } else {
                    // Notes list
                    if person.notes.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No notes yet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.25))
                            Text("Journal about \(person.name) to add notes automatically.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.15))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(person.notes) { note in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top, spacing: 12) {
                                            Circle()
                                                .fill(Color(hex: "4A9EDB"))
                                                .frame(width: 8, height: 8)
                                                .padding(.top, 6)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(note.text)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineSpacing(3)
                                                
                                                Text(note.date.formatted(.dateTime.month().day().year()))
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.white.opacity(0.4))
                                                
                                                // Link back to original log
                                                if let logID = note.logID,
                                                   let originalLog = LogStore.shared.logs.first(where: { $0.id == logID }) {
                                                    NavigationLink(destination: LogDetailView(log: originalLog)) {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "doc.text")
                                                                .font(.system(size: 10))
                                                            Text("View Original Log")
                                                                .font(.system(size: 11, weight: .semibold))
                                                        }
                                                        .foregroundColor(Color(hex: "8FA8A8").opacity(0.8))
                                                        .padding(.top, 2)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .background(Color(hex: "4A9EDB").opacity(0.07))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    Button(action: { showingAddNote = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15))
                            Text("Add Note Manually")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "8FA8A8"))
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(personName: person.name)
        }
        .onAppear {
            isLocked = UserDefaults.standard.bool(forKey: lockKey)
        }
    }
    
    func toggleLock() {
        if isLocked {
            authenticate {
                isLocked = false
                isUnlocked = false
                UserDefaults.standard.set(false, forKey: lockKey)
            }
        } else {
            isLocked = true
            isUnlocked = false
            UserDefaults.standard.set(true, forKey: lockKey)
        }
    }
    
    func authenticate(completion: (() -> Void)? = nil) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authError = "Authentication not available"
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock \(person.name)'s notes"
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    isUnlocked = true
                    authError = nil
                    completion?()
                } else {
                    authError = "Authentication failed"
                }
            }
        }
    }
}
