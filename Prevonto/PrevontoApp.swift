// Prevonto App - Root view switches based on authentication state
import SwiftUI

@main
struct PrevontoApp: App {
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// Root view that switches between auth flow and main app based on login state
struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                // User is logged in - show main app (no back button to login)
                ContentView()
            } else {
                // User is not logged in - show welcome/auth flow
                NavigationStack {
                    WelcomeView()
                }
            }
        }
        .onAppear {
            // Request HealthKit permissions on app launch if logged in
            if authManager.isLoggedIn {
                requestHealthKitPermissions()
            }
        }
        .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                requestHealthKitPermissions()
            }
        }
    }

    private func requestHealthKitPermissions() {
        let healthKitManager = HealthKitManager()
        healthKitManager.requestAuthorization { success, error in
            if success {
                print("✅ HealthKit authorized")
            } else {
                print("⚠️ HealthKit authorization denied or failed: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }
}
