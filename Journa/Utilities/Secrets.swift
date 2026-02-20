import Foundation
import KeychainAccess

struct Secrets {
    static let keychain = Keychain(service: "com.spencerjarrell.journa")
    
    static var anthropicAPIKey: String {
        get { return keychain["anthropicAPIKey"] ?? "" }
        set { keychain["anthropicAPIKey"] = newValue }
    }
    
    static var categorizePeople: Bool {
        get { return UserDefaults.standard.object(forKey: "categorizePeople") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "categorizePeople") }
    }
    
    static var categorizeCalendar: Bool {
        get { return UserDefaults.standard.object(forKey: "categorizeCalendar") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "categorizeCalendar") }
    }
    
    static var categorizeLogs: Bool {
        get { return UserDefaults.standard.object(forKey: "categorizeLogs") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "categorizeLogs") }
    }
}
