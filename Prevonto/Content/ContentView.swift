// Dashboard page for the Prevonto app
import SwiftUI
import Charts

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var stepCount: Double = 0
    @State private var calories: Double = 0
    @State private var distance: Double = 0
    @State private var heartRate: Double? = nil  // nil = no data yet
    @State private var authorizationStatus: String = "Not Requested"
    @State private var showingQuickActions = false
    @State private var isQuickLogExpanded = false
    
    // Time period selection
    @State private var selectedTimePeriod: TimePeriod = .thisMonth
    
    // Carousel states
    @State private var healthHighlightsCurrentIndex = 0
    @State private var medicationCurrentIndex = 0
    
    // Activity ring data
    @State private var caloriesProgress: Double = 0.0
    @State private var exerciseProgress: Double = 0.0
    @State private var standProgress: Double = 0.0

    // Heart rate chart data (empty = no data)
    @State private var heartRateChartData: [Double] = []

    // Loading states
    @State private var isLoadingAnalytics: Bool = false

    // AI Insights data
    @State private var aiInsights: [Insight] = []
    @State private var anomalyCount: Int = 0
    @State private var isLoadingAI: Bool = false

    // Medication adherence (0.0 - 1.0)
    @State private var adherenceProgress: Double = 0.0

    // Mood tracker data for dashboard
    @State private var latestMoodType: MoodType = .neutral
    @State private var latestMoodLabel: String = ""
    @State private var latestEnergy: Int = 0
    @State private var hasMoodData: Bool = false

    // Notification settings state
    @State private var showHeartRate: Bool = true
    @State private var showStepsActivity: Bool = true
    
    let healthKitManager = HealthKitManager()
    
    // Medication data - starts empty for new users
    @State private var medications: [Medication] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // All Dashboard Page Content that is not the floating + button
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16){
                            headerSection
                            quickHealthSection
                        }
                        healthHighlightsSection
                        medicationSection
                        moodTrackerSection
                            .onAppear {
                                // Refresh mood data when this section appears
                                loadMoodData()
                            }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color.white)
                .navigationBarHidden(true)
                .sheet(isPresented: $showingQuickActions) {
                    QuickActionsModal()
                }
                
                // Expandable quick-log FAB menu
                quickLogFABMenu
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingQuickActions) {
                QuickActionsModal()
            }
            .onAppear {
                loadHealthData()
                loadNotificationSettings()
                loadAnalyticsData()
                loadAIData()
                loadMoodData()
                loadMedications()
            }
            .onChange(of: selectedTimePeriod) { _, _ in
                loadAnalyticsData()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Refresh data when app becomes active (returning from other views)
                    loadMoodData()
                    loadHealthData()
                    loadMedications()
                }
            }
        }
    }
    
    // MARK: - Dashboard Header Section
    var headerSection: some View {
        HStack {
            // Welcome Back Message
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back!")
                    .font(.custom("Noto Sans", size: 32))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                // AI Insights Button with anomaly badge
                NavigationLink(destination: AIInsightsView()) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)

                        if anomalyCount > 0 {
                            Text("\(anomalyCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Settings Button
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Quick Health Section
    var quickHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Quick Health Snapshot subheading
                Text("Quick Health Snapshot")
                    .font(.custom("Noto Sans", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                Spacer()
                
                // Dropdown menu selection
                // Following options to select: Today, This week, This month, This year
                Menu {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button(period.rawValue) {
                            selectedTimePeriod = period
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTimePeriod.rawValue)
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                    )
                }
            }
            
            // Conditional Health Metrics Display
            HStack(spacing: 16) {
                // Only show activity rings if Steps & Activity is enabled in notifications
                if showStepsActivity {
                    NavigationLink(destination: StepsDetailsView()) {
                        activityRingsCard
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Only show heart rate if Heart Rate is enabled in notifications
                if showHeartRate {
                    NavigationLink(destination: HeartRateView()) {
                        heartRateCard
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // If both are disabled, show a placeholder
                if !showStepsActivity && !showHeartRate {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                        
                        Text("No health metrics enabled")
                            .font(.custom("Noto Sans", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                            .multilineTextAlignment(.center)
                        
                        Text("Enable metrics in Notifications settings")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Activity Rings Card
    var activityRingsCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outermost ring (Stand)
                Circle()
                    .stroke(Color(red: 0.14, green: 0.20, blue: 0.08).opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: standProgress)
                    .stroke(Color(red: 0.14, green: 0.20, blue: 0.08), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // Middle ring (Exercise)
                Circle()
                    .stroke(Color(red: 0.36, green: 0.51, blue: 0.36).opacity(0.2), lineWidth: 12)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: exerciseProgress)
                    .stroke(Color(red: 0.36, green: 0.51, blue: 0.36), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                
                // Innermost ring (Calories)
                Circle()
                    .stroke(Color(red: 0.51, green: 0.64, blue: 0.51).opacity(0.2), lineWidth: 12)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: caloriesProgress)
                    .stroke(Color(red: 0.51, green: 0.64, blue: 0.51), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
            }
            
            Text("Almost there!")
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                .padding(.top, 4)
                .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Heart Rate Card
    var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    if let hr = heartRate {
                        Text("\(Int(hr))")
                            .font(.custom("Noto Sans", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.368, green: 0.553, blue: 0.372))
                        Text("bpm")
                            .font(.custom("Noto Sans", size: 18))
                            .foregroundColor(Color(red: 0.368, green: 0.553, blue: 0.372))
                    } else {
                        Text("--")
                            .font(.custom("Noto Sans", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                        Text("bpm")
                            .font(.custom("Noto Sans", size: 18))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    }
                    Spacer()
                }

                Text(heartRate != nil ? "Avg Heart Rate" : "No data yet")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
            }
            
            // Heart rate chart with gradient
            ZStack {
                if heartRateChartData.isEmpty {
                    // No data placeholder
                    Text("Log heart rate to see chart")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                        .frame(width: 120, height: 60)
                } else {
                    // Background bars
                    HStack(spacing: 12) {
                        ForEach(0..<12) { _ in
                            Rectangle()
                                .fill(Color(red: 0.74, green: 0.77, blue: 0.82).opacity(0.25))
                                .frame(width: 1, height: 60)
                        }
                    }
                }

                // Area chart with gradient from line to bottom
                Path { path in
                    let width = 120.0
                    let height = 60.0
                    let points = heartRateChartData

                    guard !points.isEmpty else { return }

                    // Start from bottom left
                    path.move(to: CGPoint(x: 0, y: height))
                    // Draw to first point
                    path.addLine(to: CGPoint(x: 0, y: height * (1 - points[0])))

                    // Draw the line
                    for i in 1..<points.count {
                        let x = width * Double(i) / Double(points.count - 1)
                        let y = height * (1 - points[i])
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    // Close the path to bottom right
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.368, green: 0.553, blue: 0.372).opacity(0.3),
                            Color(red: 0.368, green: 0.553, blue: 0.372).opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 60)

                // Line on top
                Path { path in
                    let width = 120.0
                    let height = 60.0
                    let points = heartRateChartData

                    guard !points.isEmpty else { return }

                    path.move(to: CGPoint(x: 0, y: height * (1 - points[0])))

                    for i in 1..<points.count {
                        let x = width * Double(i) / Double(points.count - 1)
                        let y = height * (1 - points[i])
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color(red: 0.368, green: 0.553, blue: 0.372), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 120, height: 60)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Health Highlights Section
    var healthHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Health highlights")
                    .font(.custom("Noto Sans", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                Spacer()
                NavigationLink(destination: AIInsightsView()) {
                    Text("See all")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                }
            }

            if isLoadingAI {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 140)
            } else if aiInsights.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                    Text("AI insights will appear here")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    Text("Track more health metrics to get personalized insights")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(16)
            } else {
                // Carousel of AI insight cards
                TabView(selection: $healthHighlightsCurrentIndex) {
                    ForEach(Array(aiInsights.prefix(5).enumerated()), id: \.element.id) { index, insight in
                        insightCard(insight: insight)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 140)

                // Carousel progress bar
                if aiInsights.count > 1 {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(0..<min(aiInsights.count, 5), id: \.self) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(index == healthHighlightsCurrentIndex ? Color(red: 0.36, green: 0.55, blue: 0.37) : Color(red: 0.85, green: 0.85, blue: 0.85))
                                    .frame(width: index == healthHighlightsCurrentIndex ? 24 : 8, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: healthHighlightsCurrentIndex)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Insight Card
    func insightCard(insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForInsightType(insight.insight_type))
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                    .font(.system(size: 16))
                Text(insight.title)
                    .font(.custom("Noto Sans", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                    .lineLimit(1)
                Spacer()
                Text("\(Int(insight.confidence * 100))%")
                    .font(.custom("Noto Sans", size: 12))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }

            Text(insight.description)
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.50))
                .lineLimit(2)

            if insight.actionable, let action = insight.action_text {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text(action)
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(16)
    }

    private func iconForInsightType(_ type: String) -> String {
        switch type {
        case "correlation": return "arrow.triangle.2.circlepath"
        case "trend": return "chart.line.uptrend.xyaxis"
        case "anomaly": return "exclamationmark.triangle"
        default: return "lightbulb"
        }
    }
    
    // MARK: - Medication Section
    var medicationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your medication")
                .font(.custom("Noto Sans", size: 22))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))

            if medications.isEmpty {
                // Empty state for no medications
                VStack(spacing: 12) {
                    Image(systemName: "pills")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                    Text("No medications added")
                        .font(.custom("Noto Sans", size: 16))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    Text("Add medications to track reminders and adherence")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
            } else {
                // Medication card carousel, where each card display each medicine and status of either taking or skipping that medicine
                TabView(selection: $medicationCurrentIndex) {
                    ForEach(medications.indices, id: \.self) { index in
                        medicationCard(medication: medications[index])
                            .frame(width: 280)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 100)

                // Carousel progress bar for the Medication section
                if medications.count > 1 {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(medications.indices, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(index == medicationCurrentIndex ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.5))
                                    .frame(width: index == medicationCurrentIndex ? 24 : 8, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: medicationCurrentIndex)
                            }
                        }
                        Spacer()
                    }
                }
            }

            // Medication Reminders and Adherence section
            HStack(spacing: 12) {
                // Medication Reminders card
                remindersCard

                // Medication Adherence card
                adherenceCard
            }
        }
    }
    
    // MARK: - Medication Card
    func medicationCard(medication: Medication) -> some View {
        HStack {
            // Medication name and instructions to take the medicine
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.custom("Noto Sans", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                Text(medication.instructions)
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
            }
            
            Spacer()
            
            // Medication Skipped and Medication Taken buttons
            HStack(spacing: 8) {
                Button("Skipped") {
                    // Skip action
                }
                .font(.custom("Noto Sans", size: 14))
                .frame(width: 60)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.690, green: 0.698, blue: 0.764), lineWidth: 1)
                )
                .foregroundColor(Color(red: 0.690, green: 0.698, blue: 0.764))
                .cornerRadius(8)
                
                Button("Taken") {
                    // Taken action
                }
                .font(.custom("Noto Sans", size: 14))
                .frame(width: 60)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.02, green: 0.33, blue: 0.18))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(width: 325)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Reminders Card
    var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reminders Card subheading
            Text("Reminders")
                .font(.custom("Noto Sans", size: 20))
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                .padding(.top, 10)

            if medications.isEmpty {
                // Empty state
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                        .font(.system(size: 14))
                    Text("No reminders set")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                }
            } else {
                // Display each medicine user wants a reminder for
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(medications.prefix(2))) { med in
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundColor(Color(red: 0.690, green: 0.698, blue: 0.764))
                                .font(.system(size: 14))
                            Text("\(med.name), \(med.time)")
                                .font(.custom("Noto Sans", size: 14))
                                .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Adherence Card
    var adherenceCard: some View {
        // Progress ring for display user's medication adherence percentage
        HStack(spacing: 12) {
            if medications.isEmpty {
                // Empty state
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Text("--")
                        .font(.custom("Noto Sans", size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Adherence")
                        .font(.custom("Noto Sans", size: 13))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    Text("No data yet")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                }
            } else {
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: adherenceProgress)
                        .stroke(Color(red: 0.368, green: 0.553, blue: 0.372), lineWidth: 4)
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(adherenceProgress * 100))%")
                        .font(.custom("Noto Sans", size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.368, green: 0.553, blue: 0.372))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Adherence")
                        .font(.custom("Noto Sans", size: 13))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    Text(currentWeekRange)
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                    Text(currentMonthYear)
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Mood Tracker Section
    var moodTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Your Mood Tracker subheading
            HStack {
                Text("Your Mood Tracker")
                    .font(.custom("Noto Sans", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                Spacer()
                NavigationLink(destination: MoodTrackerView()) {
                    Text("See all")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                }
            }

            // Showcase the user's mood data
            NavigationLink(destination: MoodTrackerView()) {
                if hasMoodData {
                    HStack(spacing: 20) {
                        // Mood icon (custom view matching Figma)
                        MoodIconView(mood: latestMoodType, size: 50)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Mood")
                                .font(.custom("Noto Sans", size: 14))
                                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                            Text(latestMoodLabel)
                                .font(.custom("Noto Sans", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                                Text("Energy: \(latestEnergy)/10")
                                    .font(.custom("Noto Sans", size: 14))
                                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "face.dashed")
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                        Text("No mood logged yet")
                            .font(.custom("Noto Sans", size: 16))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                        Text("Tap to log your first mood")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Quick Log FAB Menu
    var quickLogFABMenu: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    // Expanded action buttons (shown when expanded)
                    if isQuickLogExpanded {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .trailing, spacing: 10) {
                                // Devices button
                                NavigationLink(destination: DevicesView()) {
                                    quickLogButton(icon: "applewatch", label: "Devices", color: Color(red: 0.50, green: 0.50, blue: 0.50))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // AI Health Insights button
                                NavigationLink(destination: AIInsightsView()) {
                                    quickLogButton(icon: "brain.head.profile", label: "AI Health", color: Color(red: 0.36, green: 0.55, blue: 0.37))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Days Tracked button
                                NavigationLink(destination: DaysTrackedView()) {
                                    quickLogButton(icon: "calendar", label: "Days Tracked", color: .purple)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // SpO2 button
                                NavigationLink(destination: SpO2View()) {
                                    quickLogButton(icon: "lungs.fill", label: "SpO2", color: .cyan)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Blood Glucose button
                                NavigationLink(destination: BloodGlucoseView()) {
                                    quickLogButton(icon: "drop.fill", label: "Blood Glucose", color: .red)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Heart Rate button
                                NavigationLink(destination: HeartRateView()) {
                                    quickLogButton(icon: "heart.fill", label: "Heart Rate", color: Color(red: 0.90, green: 0.30, blue: 0.30))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Steps & Activity button
                                NavigationLink(destination: StepsDetailsView()) {
                                    quickLogButton(icon: "figure.walk", label: "Steps & Activity", color: Color(red: 0.36, green: 0.55, blue: 0.37))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Medication button
                                NavigationLink(destination: MedicationTrackerView()) {
                                    quickLogButton(icon: "pills.fill", label: "Medication", color: .orange)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Mood button
                                NavigationLink(destination: MoodTrackerView()) {
                                    quickLogButton(icon: "face.smiling.fill", label: "Mood", color: .green)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Liquid Log button
                                NavigationLink(destination: LiquidLogView()) {
                                    quickLogButton(icon: "drop.fill", label: "Liquid Log", color: .cyan)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })

                                // Weight button
                                NavigationLink(destination: WeightTrackerView()) {
                                    quickLogButton(icon: "scalemass.fill", label: "Weight", color: .blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.spring(response: 0.3)) { isQuickLogExpanded = false }
                                })
                            }
                            .padding(.bottom, 70)
                        }
                        .frame(maxHeight: 400)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Main FAB button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isQuickLogExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isQuickLogExpanded ? "xmark" : "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.02, green: 0.33, blue: 0.18))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                            .rotationEffect(.degrees(isQuickLogExpanded ? 45 : 0))
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 34)
            }
        }
        // Tap outside to close
        .background(
            isQuickLogExpanded ?
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isQuickLogExpanded = false
                    }
                }
            : nil
        )
    }

    // Helper for quick log buttons
    private func quickLogButton(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.custom("Noto Sans", size: 14))
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Computed Properties for Dates
    private var currentWeekRange: String {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? today
        let startDay = calendar.component(.day, from: startOfWeek)
        let endDay = calendar.component(.day, from: endOfWeek)
        return "\(startDay) to \(endDay)"
    }

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Helper Functions
    private func loadHealthData() {
        // Check if HealthKit is available
        guard HealthKitManager.isHealthKitAvailable else {
            authorizationStatus = "Not Available"
            return
        }

        // Check if already authorized before requesting
        if healthKitManager.hasAnyAuthorization {
            authorizationStatus = "Authorized"
            fetchHealthData()
        } else {
            // Request authorization
            healthKitManager.requestAuthorization { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.authorizationStatus = "Authorized"
                        self.fetchHealthData()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.authorizationStatus = "Authorization Failed"
                    }
                }
            }
        }
    }

    private func fetchHealthData() {
        healthKitManager.fetchTodayStepCount { steps, error in
            if let steps = steps {
                DispatchQueue.main.async {
                    stepCount = steps
                }
            }
        }

        healthKitManager.fetchTodayCalories { cals, error in
            if let cals = cals {
                DispatchQueue.main.async {
                    calories = cals
                }
            }
        }

        healthKitManager.fetchTodayDistance { distanceValue, error in
            if let distanceValue = distanceValue {
                DispatchQueue.main.async {
                    distance = distanceValue
                }
            }
        }

        healthKitManager.fetchTodayHeartRate { hr, error in
            if let hr = hr {
                DispatchQueue.main.async {
                    heartRate = hr
                }
            }
        }
    }
    
    private func loadNotificationSettings() {
        // Load notification settings from UserDefaults
        // Set defaults if not set
        if UserDefaults.standard.object(forKey: "showHeartRate") == nil {
            UserDefaults.standard.set(true, forKey: "showHeartRate")
        }
        if UserDefaults.standard.object(forKey: "showStepsActivity") == nil {
            UserDefaults.standard.set(true, forKey: "showStepsActivity")
        }

        // Update state variables
        showHeartRate = UserDefaults.standard.bool(forKey: "showHeartRate")
        showStepsActivity = UserDefaults.standard.bool(forKey: "showStepsActivity")
    }

    private func loadAnalyticsData() {
        isLoadingAnalytics = true

        Task {
            do {
                let timeRange = selectedTimePeriod.toTimeRange

                // Load heart rate and activity data in parallel
                async let heartRateData = AnalyticsAPI.shared.getTimeSeries(metricType: "heart_rate", range: timeRange)
                async let activityStats = AnalyticsAPI.shared.getStatistics(metricType: "steps_activity", range: timeRange)

                let (heartRateResponse, activityResponse) = try await (heartRateData, activityStats)

                await MainActor.run {
                    // Update heart rate chart data
                    heartRateChartData = normalizeHeartRateData(response: heartRateResponse)

                    // Update activity ring progress from statistics
                    updateActivityProgress(from: activityResponse)

                    isLoadingAnalytics = false
                }
            } catch {
                await MainActor.run {
                    isLoadingAnalytics = false
                    // Keep existing/default values on error
                }
            }
        }
    }

    private func normalizeHeartRateData(response: TimeSeriesResponse) -> [Double] {
        let bpmValues = response.data_points.compactMap { $0.value["bpm"] }

        // Return empty array if no data - don't fake it
        guard !bpmValues.isEmpty else {
            return []
        }

        let minBPM = bpmValues.min() ?? 50
        let maxBPM = bpmValues.max() ?? 120
        let range = maxBPM - minBPM

        if range == 0 {
            return bpmValues.map { _ in 0.5 }
        }

        // Normalize BPM values to 0-1 range for chart display
        return bpmValues.map { bpm in
            min(max((bpm - minBPM) / range, 0.1), 0.9)
        }
    }

    private func updateActivityProgress(from response: StatisticsResponse) {
        // Calculate progress based on statistics and targets
        // Targets: Calories 8000, Exercise 30 min, Stand 12 hours (daily targets)
        let caloriesTarget = 8000.0
        let exerciseTarget = 30.0
        let standTarget = 12.0

        if let avgCalories = response.average["calories"] {
            let totalCalories = avgCalories * Double(response.count)
            caloriesProgress = min(totalCalories / caloriesTarget, 1.0)
        }

        if let avgExercise = response.average["exercise_minutes"] {
            let totalExercise = avgExercise * Double(response.count)
            exerciseProgress = min(totalExercise / exerciseTarget, 1.0)
        }

        if let avgStand = response.average["stand_hours"] {
            let totalStand = avgStand * Double(response.count)
            standProgress = min(totalStand / standTarget, 1.0)
        }
    }

    private func loadAIData() {
        isLoadingAI = true

        Task {
            do {
                async let insightsTask = AIAgentAPI.shared.getInsights(daysBack: 7)
                async let anomalyCountTask = AIAgentAPI.shared.getAnomalyCount()

                let (loadedInsights, loadedAnomalyCount) = try await (insightsTask, anomalyCountTask)

                await MainActor.run {
                    aiInsights = loadedInsights
                    anomalyCount = loadedAnomalyCount
                    isLoadingAI = false
                }
            } catch {
                await MainActor.run {
                    isLoadingAI = false
                    // Keep empty state on error
                    print("❌ Failed to load AI data: \(error)")
                }
            }
        }
    }

    private func loadMoodData() {
        // Load mood data from local repository
        let repository = LocalMoodRepository()
        let entries = repository.fetchEntries()

        if let latestEntry = entries.first {
            hasMoodData = true
            latestEnergy = latestEntry.energy

            // Map mood value to MoodType and label
            switch latestEntry.moodValue {
            case "Very Sad":
                latestMoodType = .verySad
                latestMoodLabel = "Very Sad"
            case "Sad":
                latestMoodType = .sad
                latestMoodLabel = "Sad"
            case "Neutral":
                latestMoodType = .neutral
                latestMoodLabel = "Neutral"
            case "Happy":
                latestMoodType = .happy
                latestMoodLabel = "Happy"
            case "Very Happy":
                latestMoodType = .veryHappy
                latestMoodLabel = "Very Happy"
            default:
                latestMoodType = .neutral
                latestMoodLabel = latestEntry.moodValue
            }
        } else {
            hasMoodData = false
        }
    }

    private func loadMedications() {
        // Load medications from UserDefaults (same storage as MedicationTrackerView)
        guard let data = UserDefaults.standard.data(forKey: "trackedMedications") else {
            medications = []
            return
        }

        do {
            let decoder = JSONDecoder()
            let tracked = try decoder.decode([TrackedMedicationDTO].self, from: data)
            medications = tracked.map { med in
                let instructions = [med.dosage, med.frequency]
                    .compactMap { $0 }
                    .joined(separator: " - ")
                return Medication(
                    name: med.name,
                    instructions: instructions.isEmpty ? "As directed" : instructions,
                    time: med.reminderTime ?? "No time set"
                )
            }
        } catch {
            print("Failed to load medications: \(error)")
            medications = []
        }
    }
}

// DTO for decoding medications from MedicationTrackerView storage
private struct TrackedMedicationDTO: Codable {
    var id: UUID
    var name: String
    var dosage: String?
    var frequency: String?
    var reminderTime: String?
    var lastTakenDate: Date?
    var todayStatus: String?
}

// MARK: - TimePeriod to TimeRange Extension
extension TimePeriod {
    var toTimeRange: TimeRange {
        switch self {
        case .today: return .day
        case .thisWeek: return .week
        case .thisMonth: return .month
        case .thisYear: return .year
        }
    }
}

// Modal and its contents that gets loaded when the user clicks on the floating + button
struct AddItemModal: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                HStack {
                    Text("Quick Actions")
                        .font(.custom("Noto Sans", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                            .frame(width: 30, height: 30)
                            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                // 2x2 Grid of options
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    NavigationLink(destination: WeightTrackerView()) {
                        AddItemButtonView(
                            icon: "scalemass.fill",
                            title: "Input Weight",
                            color: Color.blue
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: MoodTrackerView()) {
                        AddItemButtonView(
                            icon: "face.smiling.fill",
                            title: "Input Mood",
                            color: Color.green
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // Add medication action
                        dismiss()
                    }) {
                        AddItemButtonView(
                            icon: "pills.fill",
                            title: "Add Medication",
                            color: Color.orange
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: AIChatView()) {
                        AddItemButtonView(
                            icon: "brain.head.profile",
                            title: "AI Chat",
                            color: Color(red: 0.36, green: 0.55, blue: 0.37)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .background(Color.white)
        }
    }
}

// Add Item Button Component (the floating + button in Dashboard page)
struct AddItemButtonView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text(title)
                .font(.custom("Noto Sans", size: 16))
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Supporting Models and Enums
enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This week"
    case thisMonth = "This month"
    case thisYear = "This year"
}

struct Medication: Identifiable {
    let id = UUID()
    let name: String
    let instructions: String
    let time: String
}

// MARK: - Quick Actions Modal
struct QuickActionsModal: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Quick Actions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    NavigationLink(destination: WeightTrackerView()) {
                        QuickActionButtonView(
                            icon: "scalemass.fill",
                            title: "Input Weight",
                            color: .blue
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: MoodTrackerView()) {
                        QuickActionButtonView(
                            icon: "face.smiling.fill",
                            title: "Input Mood",
                            color: .green
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: BloodGlucoseView()) {
                        QuickActionButtonView(
                            icon: "drop.fill",
                            title: "Blood Glucose",
                            color: .red
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                
                Spacer()
                
                // Navigation buttons for other features
                VStack(spacing: 12) {
                    NavigationLink("SpO2 Display", destination: SpO2View())
                        .buttonStyle(.borderedProminent)
                    NavigationLink("Steps Details", destination: StepsDetailsView())
                        .buttonStyle(.borderedProminent)
                    NavigationLink("Heart Rate", destination: HeartRateView())
                        .buttonStyle(.borderedProminent)
                    NavigationLink("Days Tracked", destination: DaysTrackedView())
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Button Components
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButtonView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "icon")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
