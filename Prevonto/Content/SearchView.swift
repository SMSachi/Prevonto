// Search view for finding features and health pages
import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    struct SearchItem: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let destination: AnyView
        let keywords: [String]
    }

    let searchItems: [SearchItem] = [
        SearchItem(name: "Weight Tracker", icon: "scalemass.fill", destination: AnyView(WeightTrackerView()), keywords: ["weight", "scale", "mass", "body"]),
        SearchItem(name: "Mood Tracker", icon: "face.smiling.fill", destination: AnyView(MoodTrackerView()), keywords: ["mood", "emotion", "feeling", "energy", "happy", "sad"]),
        SearchItem(name: "Heart Rate", icon: "heart.fill", destination: AnyView(HeartRateView()), keywords: ["heart", "bpm", "pulse", "cardiac"]),
        SearchItem(name: "Steps & Activity", icon: "figure.walk", destination: AnyView(StepsDetailsView()), keywords: ["steps", "walk", "activity", "exercise", "calories"]),
        SearchItem(name: "Blood Glucose", icon: "drop.fill", destination: AnyView(BloodGlucoseView()), keywords: ["blood", "glucose", "sugar", "diabetes"]),
        SearchItem(name: "SpO2", icon: "lungs.fill", destination: AnyView(SpO2View()), keywords: ["oxygen", "spo2", "saturation", "breathing"]),
        SearchItem(name: "AI Insights", icon: "brain.head.profile", destination: AnyView(AIInsightsView()), keywords: ["ai", "insight", "analysis", "recommendation"]),
        SearchItem(name: "AI Chat", icon: "message.fill", destination: AnyView(AIChatView()), keywords: ["chat", "message", "ask", "question"]),
        SearchItem(name: "Settings", icon: "gearshape.fill", destination: AnyView(SettingsView()), keywords: ["settings", "config", "preferences", "account"]),
        SearchItem(name: "Devices", icon: "applewatch", destination: AnyView(DevicesView()), keywords: ["devices", "wearable", "apple watch", "connect", "health"]),
        SearchItem(name: "Analytics", icon: "chart.bar.fill", destination: AnyView(AnalyticsView()), keywords: ["analytics", "chart", "stats", "data"]),
        SearchItem(name: "Days Tracked", icon: "calendar", destination: AnyView(DaysTrackedView()), keywords: ["days", "tracked", "streak", "calendar"])
    ]

    var filteredItems: [SearchItem] {
        if searchText.isEmpty {
            return searchItems
        }
        return searchItems.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    TextField("Search features...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                        }
                    }
                }
                .padding(12)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .cornerRadius(10)
                .padding()

                // Results
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredItems) { item in
                            NavigationLink(destination: item.destination) {
                                HStack(spacing: 16) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                                        .frame(width: 40, height: 40)
                                        .background(Color(red: 0.36, green: 0.55, blue: 0.37).opacity(0.1))
                                        .cornerRadius(8)

                                    Text(item.name)
                                        .font(.custom("Noto Sans", size: 16))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        if filteredItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                                Text("No results found")
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                                Text("Try a different search term")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                }
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
