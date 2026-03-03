import Foundation

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var accessToken: String?
    
    private let tokenKey = "access_token"
    
    private init() {
        // Load token from storage on init
        self.accessToken = UserDefaults.standard.string(forKey: tokenKey)
        self.isLoggedIn = accessToken != nil
    }
    
    func saveToken(_ token: String) {
        self.accessToken = token
        self.isLoggedIn = true
        UserDefaults.standard.set(token, forKey: tokenKey)
        print("✅ Token saved")
    }
    
    func clearToken() {
        self.accessToken = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
        print("🚪 Token cleared")
    }
    
    func getToken() -> String? {
        return accessToken
    }
}
