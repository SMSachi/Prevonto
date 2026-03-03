//
//  AIInsightsView.swift
//  Prevonto
//
//  Created by Sachi Shah on 1/19/26.
//
import SwiftUI

struct AIInsightsView: View {
    @State private var insights: [Insight] = []
    @State private var anomalies: [Anomaly] = []
    @State private var dailySummary: DailySummary?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    Text("Summary").tag(0)
                    Text("Insights").tag(1)
                    Text("Anomalies").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading insights...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadData()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if selectedTab == 0 {
                                DailySummaryView(summary: dailySummary)
                            } else if selectedTab == 1 {
                                InsightsListView(insights: insights)
                            } else {
                                AnomaliesListView(anomalies: anomalies)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Health Insights")
            .onAppear { loadData() }
            .refreshable { loadData() }
        }
    }
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let insightsTask = AIAgentAPI.shared.getInsights()
                async let anomaliesTask = AIAgentAPI.shared.getAnomalies()
                async let summaryTask = AIAgentAPI.shared.getDailySummary()
                
                let (loadedInsights, loadedAnomalies, loadedSummary) = try await (insightsTask, anomaliesTask, summaryTask)
                
                await MainActor.run {
                    insights = loadedInsights
                    anomalies = loadedAnomalies
                    dailySummary = loadedSummary
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if error.localizedDescription.contains("404") {
                        errorMessage = "No data available yet. Track some metrics first!"
                    } else {
                        errorMessage = "Failed to load insights"
                    }
                    print("❌ Insights error: \(error)")
                }
            }
        }
    }
}

struct DailySummaryView: View {
    let summary: DailySummary?

    // Check if summary seems to be real data vs mock/default
    private var hasRealData: Bool {
        guard let summary = summary else { return false }
        // If there are insights or the summary text contains real info
        return !summary.insights.isEmpty || summary.anomalies.count > 0
    }

    var body: some View {
        if let summary = summary {
            VStack(alignment: .leading, spacing: 16) {
                // Overall Score
                if let score = summary.overall_score, hasRealData {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Health Score")
                                .font(.headline)
                            Text("\(score)/100")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(scoreColor(score))
                        }
                        Spacer()
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100)
                            .stroke(scoreColor(score), lineWidth: 10)
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                // Summary Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Summary")
                        .font(.headline)
                    if hasRealData {
                        Text(summary.summary_text)
                            .foregroundColor(.gray)
                    } else {
                        Text("Start tracking your health metrics to see personalized insights. Log your mood, weight, and connect your wearables to see trends and recommendations.")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // Metrics Tracked - only show if we have actual metrics
                if !summary.metrics_tracked.isEmpty && hasRealData {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metrics Tracked Today")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(summary.metrics_tracked, id: \.self) { metric in
                                Text(formatMetricName(metric))
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                } else if !hasRealData {
                    // Empty state for no data
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                        Text("No metrics tracked yet")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                        Text("Log some health data to see AI-powered insights")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                Text("No summary available")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                Text("Track some health metrics to get started")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private func formatMetricName(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct InsightsListView: View {
    let insights: [Insight]
    
    var body: some View {
        if insights.isEmpty {
            Text("No insights available yet")
                .foregroundColor(.gray)
                .padding()
        } else {
            ForEach(insights) { insight in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: iconForInsightType(insight.insight_type))
                            .foregroundColor(.blue)
                        Text(insight.title)
                            .font(.headline)
                        Spacer()
                        Text("\(Int(insight.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(insight.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if insight.actionable, let action = insight.action_text {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text(action)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(8)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func iconForInsightType(_ type: String) -> String {
        switch type {
        case "correlation": return "arrow.triangle.2.circlepath"
        case "trend": return "chart.line.uptrend.xyaxis"
        case "anomaly": return "exclamationmark.triangle"
        default: return "lightbulb"
        }
    }
}

struct AnomaliesListView: View {
    let anomalies: [Anomaly]
    
    var body: some View {
        if anomalies.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("No anomalies detected")
                    .font(.headline)
                Text("Your metrics are within normal ranges")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        } else {
            ForEach(anomalies) { anomaly in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(severityColor(anomaly.severity))
                        Text(formatMetricName(anomaly.metric_type))
                            .font(.headline)
                        Spacer()
                        Text(anomaly.severity.uppercased())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor(anomaly.severity).opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text(anomaly.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let recommendation = anomaly.recommendation {
                        HStack {
                            Image(systemName: "heart.text.square")
                                .foregroundColor(.red)
                            Text(recommendation)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(severityColor(anomaly.severity).opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .blue
        }
    }
    
    private func formatMetricName(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// Helper for flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
            self.positions = positions
        }
    }
}
