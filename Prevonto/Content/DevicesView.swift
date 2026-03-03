// Devices page for the Prevonto app
import SwiftUI

struct DevicesView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isSearching = false
    @State private var isHealthKitAuthorized = false
    @State private var hasHealthData = false

    let healthKitManager = HealthKitManager()

    // Paired devices - will show Apple Health connection if authorized
    var pairedDevices: [Device] {
        if isHealthKitAuthorized {
            return [Device(name: "Apple Health", type: .appleHealth, isConnected: hasHealthData)]
        }
        return []
    }

    // No nearby devices shown - connection is via Health app
    @State private var nearbyDevices: [Device] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Devices Content
                    ScrollView {
                        VStack(spacing: 24) {
                            pairNewDeviceButton

                            // Connected Devices Section
                            if !pairedDevices.isEmpty {
                                historySection
                            }

                            Spacer(minLength: 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    checkHealthKitStatus()
                }
            }
        }
    }

    private func checkHealthKitStatus() {
        // First check if HealthKit is even available
        guard HealthKitManager.isHealthKitAvailable else {
            isHealthKitAuthorized = false
            hasHealthData = false
            return
        }

        // Check if we already have authorization
        if healthKitManager.hasAnyAuthorization {
            isHealthKitAuthorized = true
            // Check if we actually have health data
            healthKitManager.fetchTodayStepCount { steps, _ in
                DispatchQueue.main.async {
                    self.hasHealthData = (steps ?? 0) > 0
                }
            }
        } else {
            // Not authorized yet - don't auto-request, let user tap button
            isHealthKitAuthorized = false
            hasHealthData = false
        }
    }
    
    // Devices Header Section
    var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                // Back Button to return to the Dashboard page
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
                
                Text("Devices")
                    .font(.custom("Noto Sans", size: 28))
                    .fontWeight(.black)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                
                Spacer()
                
                // Invisible spacer to balance the back button
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 0)
            .background(Color.white)
        }
    }
    
    // Connect to Health App Button
    var pairNewDeviceButton: some View {
        VStack(spacing: 16) {
            if !isHealthKitAuthorized {
                Button(action: {
                    connectToHealthApp()
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("Connect to Apple Health")
                            .font(.custom("Noto Sans", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())

                Text("Connect Prevonto to Apple Health to sync data from your wearables like Apple Watch, Fitbit, and other health devices.")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                    Text("Connected to Apple Health")
                        .font(.custom("Noto Sans", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(red: 0.36, green: 0.55, blue: 0.37).opacity(0.1))
                .cornerRadius(16)

                Text("Your health data from Apple Watch and other devices is syncing automatically through Apple Health.")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func connectToHealthApp() {
        healthKitManager.requestAuthorization { success, error in
            DispatchQueue.main.async {
                self.isHealthKitAuthorized = success
                if success {
                    self.healthKitManager.fetchTodayStepCount { steps, _ in
                        DispatchQueue.main.async {
                            self.hasHealthData = (steps ?? 0) > 0
                        }
                    }
                }
            }
        }
    }
    
    // Connected Devices Section
    var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("History")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(pairedDevices) { device in
                    DeviceRowView(device: device)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Device Row Component
struct DeviceRowView: View {
    let device: Device
    
    var body: some View {
        HStack(spacing: 16) {
            // Device Icon
            Image(systemName: device.iconName)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                .frame(width: 40, height: 40)
            
            // Device Info
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.custom("Noto Sans", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                
                Text(device.isConnected ? "Connected" : "Not Connected")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(device.isConnected ? Color(red: 0.36, green: 0.55, blue: 0.37) : Color(red: 0.60, green: 0.60, blue: 0.60))
            }
            
            Spacer()
            
            // Connection Status
            Circle()
                .fill(device.isConnected ? Color(red: 0.36, green: 0.55, blue: 0.37) : Color(red: 0.85, green: 0.85, blue: 0.85))
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Device Model
struct Device: Identifiable {
    let id = UUID()
    let name: String
    let type: DeviceType
    let isConnected: Bool
    
    var iconName: String {
        switch type {
        case .appleWatch:
            return "applewatch"
        case .appleHealth:
            return "heart.fill"
        case .other:
            return "speaker.wave.2.fill"
        }
    }
}

enum DeviceType {
    case appleWatch
    case appleHealth
    case other
}

// Preview
struct DevicesView_Previews: PreviewProvider {
    static var previews: some View {
        DevicesView()
    }
}
