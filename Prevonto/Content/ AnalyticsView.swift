//
//   AnalyticsView.swift
//  Prevonto
//
//  Created by Sachi Shah on 1/19/26.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var selectedMetric: String = "heart_rate"
    @State private var selectedRange: TimeRange = .week
    @State private var timeSeriesData: TimeSeriesResponse?
    @State private var statistics: StatisticsResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let metrics = [
        ("Heart Rate", "heart_rate", "heart.fill", Color.red),
        ("Blood Pressure", "blood_pressure", "waveform.path.ecg", Color.pink),
        ("Blood Glucose", "blood_glucose", "drop.fill", Color.purple),
        ("SpO2", "spo2", "lungs.fill", Color.blue),
        ("Weight", "weight", "scalemass.fill", Color.orange),
        ("Steps", "steps_activity", "figure.walk", Color.green)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Metric Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(metrics, id: \.1) { name, type, icon, color in
                                MetricButton(
                                    name: name,
                                    icon: icon,
                                    color: color,
                                    isSelected: selectedMetric == type
                                ) {
                                    selectedMetric = type
                                    loadData()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Time Range Selector
                    Picker("Range", selection: $selectedRange) {
                        Text("Day").tag(TimeRange.day)
                        Text("Week").tag(TimeRange.week)
                        Text("Month").tag(TimeRange.month)
                        Text("Year").tag(TimeRange.year)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedRange) { _ in loadData() }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        // Statistics Cards
                        if let stats = statistics {
                            StatisticsCardsView(statistics: stats)
                                .padding(.horizontal)
                        }
                        
                        // Chart
                        if let data = timeSeriesData, !data.data_points.isEmpty {
                            ChartView(data: data, metricType: selectedMetric)
                                .frame(height: 250)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .onAppear { loadData() }
        }
    }
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let timeSeries = AnalyticsAPI.shared.getTimeSeries(metricType: selectedMetric, range: selectedRange)
                async let stats = AnalyticsAPI.shared.getStatistics(metricType: selectedMetric, range: selectedRange)
                
                let (ts, st) = try await (timeSeries, stats)
                
                await MainActor.run {
                    timeSeriesData = ts
                    statistics = st
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if error.localizedDescription.contains("404") {
                        errorMessage = "No data available for this metric"
                    } else {
                        errorMessage = "Failed to load analytics data"
                    }
                    print("❌ Analytics error: \(error)")
                }
            }
        }
    }
}

struct MetricButton: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(name)
                    .font(.caption)
            }
            .frame(width: 90, height: 80)
            .foregroundColor(isSelected ? .white : color)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct StatisticsCardsView: View {
    let statistics: StatisticsResponse
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "Average", value: formatValue(statistics.average), color: .blue)
                StatCard(title: "Min", value: formatValue(statistics.minimum), color: .green)
            }
            
            HStack(spacing: 12) {
                StatCard(title: "Max", value: formatValue(statistics.maximum), color: .orange)
                StatCard(
                    title: "Trend",
                    value: trendEmoji(statistics.trend),
                    color: trendColor(statistics.trend)
                )
            }
        }
    }
    
    private func formatValue(_ dict: [String: Double]) -> String {
        if let bpm = dict["bpm"] {
            return "\(Int(bpm))"
        } else if let value = dict["value"] {
            return String(format: "%.1f", value)
        } else if let weight = dict["weight"] {
            return String(format: "%.1f", weight)
        } else if let steps = dict["steps"] {
            return "\(Int(steps))"
        } else if let systolic = dict["systolic"], let diastolic = dict["diastolic"] {
            return "\(Int(systolic))/\(Int(diastolic))"
        }
        return "--"
    }
    
    private func trendEmoji(_ trend: String) -> String {
        switch trend {
        case "increasing": return "📈"
        case "decreasing": return "📉"
        default: return "➡️"
        }
    }
    
    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "increasing": return .green
        case "decreasing": return .red
        default: return .gray
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ChartView: View {
    let data: TimeSeriesResponse
    let metricType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trend Over Time")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(data.data_points.enumerated()), id: \.offset) { index, point in
                        if let value = getChartValue(from: point.value) {
                            LineMark(
                                x: .value("Time", index),
                                y: .value("Value", value)
                            )
                            .foregroundStyle(.blue)
                            
                            PointMark(
                                x: .value("Time", index),
                                y: .value("Value", value)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                }
                .chartYAxisLabel(data.data_points.first?.unit ?? "")
            } else {
                // Fallback for iOS 15
                Text("Charts require iOS 16+")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    private func getChartValue(from dict: [String: Double]) -> Double? {
        if let bpm = dict["bpm"] {
            return bpm
        } else if let value = dict["value"] {
            return value
        } else if let weight = dict["weight"] {
            return weight
        } else if let steps = dict["steps"] {
            return steps
        } else if let systolic = dict["systolic"] {
            return systolic // Use systolic for blood pressure
        }
        return nil
    }
}
