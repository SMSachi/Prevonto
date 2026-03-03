import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isLoggedIn: Bool = false
    @Published var accessToken: String?
    @Published var isRefreshing: Bool = false
    @Published var authError: String?

    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let tokenExpiryKey = "token_expiry"

    private var refreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load tokens from storage on init
        self.accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        self.isLoggedIn = accessToken != nil

        // Check token validity on init
        if isLoggedIn {
            checkTokenValidity()
        }
    }

    // MARK: - Token Management

    func saveTokens(accessToken: String, refreshToken: String? = nil, expiresIn: Int? = nil) {
        self.accessToken = accessToken
        self.isLoggedIn = true
        self.authError = nil
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)

        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        }

        if let expiresIn = expiresIn {
            let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            UserDefaults.standard.set(expiryDate, forKey: tokenExpiryKey)
            scheduleTokenRefresh(expiresIn: expiresIn)
        }

        print("✅ Tokens saved")
    }

    func saveToken(_ token: String) {
        saveTokens(accessToken: token)
    }

    func clearToken() {
        self.accessToken = nil
        self.isLoggedIn = false
        self.authError = nil
        refreshTask?.cancel()
        refreshTask = nil

        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        print("🚪 Tokens cleared")
    }

    func getToken() -> String? {
        // Return in-memory token if available, otherwise check UserDefaults
        if let token = accessToken {
            return token
        }
        // Fallback to UserDefaults in case of timing issues
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    // MARK: - Token Refresh

    private func scheduleTokenRefresh(expiresIn: Int) {
        refreshTask?.cancel()

        // Refresh 5 minutes before expiry, or halfway through if short-lived
        let refreshDelay = max(Double(expiresIn) - 300, Double(expiresIn) / 2)

        refreshTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(refreshDelay * 1_000_000_000))
            if !Task.isCancelled {
                await performTokenRefresh()
            }
        }
    }

    @MainActor
    func performTokenRefresh() async {
        guard let refreshToken = getRefreshToken() else {
            print("⚠️ No refresh token available")
            return
        }

        guard !isRefreshing else {
            print("⚠️ Already refreshing token")
            return
        }

        isRefreshing = true

        do {
            let response = try await AuthAPI.shared.refreshToken(refreshToken: refreshToken)
            saveTokens(
                accessToken: response.access_token,
                refreshToken: response.refresh_token,
                expiresIn: response.expires_in
            )
            print("✅ Token refreshed successfully")
        } catch {
            print("❌ Token refresh failed: \(error)")
            // If refresh fails, user needs to log in again
            authError = "Session expired. Please log in again."
            clearToken()
        }

        isRefreshing = false
    }

    // MARK: - Token Validation

    func checkTokenValidity() {
        Task {
            await validateSession()
        }
    }

    @MainActor
    func validateSession() async -> Bool {
        guard accessToken != nil else {
            return false
        }

        // Check if token is expired locally first
        if let expiryDate = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date {
            if Date() >= expiryDate {
                // Token expired, try to refresh
                await performTokenRefresh()
                return isLoggedIn
            }
        }

        // Validate with server
        do {
            let isValid = try await AuthAPI.shared.validateToken()
            if !isValid {
                // Try to refresh
                await performTokenRefresh()
            }
            return isLoggedIn
        } catch {
            print("❌ Token validation failed: \(error)")
            return false
        }
    }

    // MARK: - Auth Actions

    @MainActor
    func login(email: String, password: String) async throws {
        let response = try await AuthAPI.shared.login(email: email, password: password)
        saveTokens(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            expiresIn: response.expires_in
        )
    }

    @MainActor
    func register(email: String, password: String, fullName: String) async throws {
        let response = try await AuthAPI.shared.register(email: email, password: password, fullName: fullName)
        saveTokens(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            expiresIn: response.expires_in
        )
    }

    @MainActor
    func logout() async {
        try? await AuthAPI.shared.logout()
        clearToken()
    }
}
