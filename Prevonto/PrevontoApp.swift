// Prevonto App - Root view switches based on authentication state
import SwiftUI
import UserNotifications

@main
struct PrevontoApp: App {
    @StateObject private var authManager = AuthManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// App Delegate for handling notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register notification categories with actions
        registerNotificationCategories()

        return true
    }

    private func registerNotificationCategories() {
        // Define actions for medication reminders
        let takenAction = UNNotificationAction(
            identifier: "MEDICATION_TAKEN",
            title: "Taken",
            options: [.foreground]
        )

        let skippedAction = UNNotificationAction(
            identifier: "MEDICATION_SKIPPED",
            title: "Skipped",
            options: [.destructive]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "MEDICATION_SNOOZE",
            title: "Remind in 10 min",
            options: []
        )

        // Create medication reminder category
        let medicationCategory = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, skippedAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([medicationCategory])
    }

    // Handle notifications when app is in foreground - show them anyway
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification actions (Taken, Skipped, Snooze)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier

        // Check if this is a medication notification
        if identifier.hasPrefix("med_") {
            let medIdString = String(identifier.dropFirst(4)) // Remove "med_" prefix

            switch actionIdentifier {
            case "MEDICATION_TAKEN":
                markMedication(id: medIdString, status: "taken")
                // Remove any pending follow-up notifications
                removeFollowUpNotifications(for: identifier)

            case "MEDICATION_SKIPPED":
                markMedication(id: medIdString, status: "skipped")
                // Remove any pending follow-up notifications
                removeFollowUpNotifications(for: identifier)

            case "MEDICATION_SNOOZE":
                // Schedule another notification in 10 minutes
                scheduleSnoozeNotification(originalIdentifier: identifier, notification: response.notification)

            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification - open app (do nothing special)
                break

            case UNNotificationDismissActionIdentifier:
                // User dismissed - schedule follow-up reminder in 5 minutes
                scheduleFollowUpReminder(originalIdentifier: identifier, notification: response.notification)

            default:
                break
            }
        }

        completionHandler()
    }

    private func markMedication(id: String, status: String) {
        // Load medications from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "trackedMedications"),
              var medications = try? JSONDecoder().decode([MedicationData].self, from: data) else {
            return
        }

        // Find and update the medication
        if let index = medications.firstIndex(where: { $0.id.uuidString == id }) {
            medications[index].todayStatus = status

            // Update daily history
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateKey = formatter.string(from: Date())
            medications[index].dailyHistory[dateKey] = status

            if status == "taken" {
                medications[index].lastTakenDate = Date()
            }

            // Save back to UserDefaults
            if let encoded = try? JSONEncoder().encode(medications) {
                UserDefaults.standard.set(encoded, forKey: "trackedMedications")
            }
        }
    }

    private func scheduleSnoozeNotification(originalIdentifier: String, notification: UNNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.request.content.title
        content.body = notification.request.content.body
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        // Trigger in 10 minutes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(originalIdentifier)_snooze_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleFollowUpReminder(originalIdentifier: String, notification: UNNotification) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(notification.request.content.title)"
        content.body = "Don't forget! \(notification.request.content.body)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        // Trigger in 5 minutes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(originalIdentifier)_followup_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func removeFollowUpNotifications(for baseIdentifier: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let followUps = requests.filter {
                $0.identifier.hasPrefix(baseIdentifier) &&
                ($0.identifier.contains("_snooze_") || $0.identifier.contains("_followup_"))
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: followUps.map { $0.identifier }
            )
        }
    }
}

// Simple struct for decoding medication data in AppDelegate
struct MedicationData: Codable {
    var id: UUID
    var name: String
    var dosage: String?
    var frequency: String?
    var reminderTime: String?
    var lastTakenDate: Date?
    var todayStatus: String
    var dailyHistory: [String: String]
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
