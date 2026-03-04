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

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                if authManager.isNewRegistration {
                    // New user just signed up - show onboarding
                    NavigationStack {
                        OnboardingFlowView()
                    }
                } else {
                    // Existing user logged in - go straight to dashboard
                    ContentView()
                }
            } else {
                // User is not logged in - show welcome/auth flow
                NavigationStack {
                    WelcomeView()
                }
            }
        }
        .onAppear {
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
