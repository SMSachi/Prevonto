// Onboarding page 8 out of 9 prompts user for any and all medication they currently take
import SwiftUI
import UserNotifications

struct MedicationSelectionView: View {
    @State private var selectedMeds: [String] = []
    @State private var searchQuery: String = ""
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    let allMedications = [
        "Abilify", "Abilify Maintena", "Abiraterone", "Acetaminophen",
        "Actemra", "Aceon", "Accutane", "Acetasol HC", "Aspirin", "Ibuprofen", "Xanax", "Zoloft"
    ]

    var filteredMedications: [String] {
        if searchQuery.isEmpty {
            return []
        } else {
            return allMedications.filter { $0.lowercased().contains(searchQuery.lowercased()) }
        }
    }

    // Check if user can add custom medication
    var canAddCustomMedication: Bool {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !selectedMeds.contains(trimmed) && !allMedications.contains(where: { $0.lowercased() == trimmed.lowercased() })
    }

    var body: some View {
        OnboardingStepWrapper(step: step, title: "Which medications are\nyou currently taking?") {
            VStack(spacing: 16) {
                // Search bar with add button
                HStack(spacing: 8) {
                    TextField("Search or type medication name", text: $searchQuery)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            HStack {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                        )

                    // Add custom medication button
                    if canAddCustomMedication {
                        Button(action: {
                            addCustomMedication()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 0.39, green: 0.59, blue: 0.38))
                        }
                    }
                }

                // Medication search result list
                if !filteredMedications.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(filteredMedications, id: \.self) { med in
                            Button(action: {
                                toggleSelection(for: med)
                            }) {
                                HStack {
                                    Text(med)
                                        .foregroundColor(selectedMeds.contains(med) ? .white : .primary)
                                    Spacer()
                                    if selectedMeds.contains(med) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedMeds.contains(med) ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.white)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                } else if canAddCustomMedication {
                    // Show hint to add custom medication
                    Text("Tap + to add \"\(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }

                // Selected chips
                if !selectedMeds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected:")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedMeds, id: \.self) { med in
                                    HStack(spacing: 4) {
                                        Text(med)
                                            .font(.footnote)
                                        Image(systemName: "xmark.circle.fill")
                                            .onTapGesture {
                                                selectedMeds.removeAll { $0 == med }
                                            }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Next button
                Button {
                    saveAndContinue()
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                            .cornerRadius(12)
                    } else {
                        Text("Next")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                            .cornerRadius(12)
                    }
                }
                .disabled(isSaving)
            }
        }
    }

    private func toggleSelection(for medication: String) {
        if selectedMeds.contains(medication) {
            selectedMeds.removeAll { $0 == medication }
        } else {
            selectedMeds.append(medication)
        }
    }

    private func addCustomMedication() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !selectedMeds.contains(trimmed) {
            selectedMeds.append(trimmed)
            searchQuery = ""  // Clear search after adding
        }
    }

    private func saveAndContinue() {
        isSaving = true

        // Save to local storage for dashboard display
        saveToLocalStorage()

        Task {
            do {
                let medicationDTOs = selectedMeds.map { MedicationDTO(name: $0, dosage: nil, frequency: nil) }
                try await OnboardingAPI.shared.saveMedications(medicationDTOs)
                await MainActor.run {
                    isSaving = false
                    next()
                }
            } catch {
                print("❌ Failed to save medications: \(error)")
                await MainActor.run {
                    isSaving = false
                    next()
                }
            }
        }
    }

    private func saveToLocalStorage() {
        // Use same structure as TrackedMedication in MedicationTrackerView
        struct SavedMedication: Codable {
            var id: UUID
            var name: String
            var dosage: String?
            var frequency: String?
            var reminderTime: String?
            var lastTakenDate: Date?
            var todayStatus: String
            var dailyHistory: [String: String]
        }

        let savedMeds = selectedMeds.map { medName in
            SavedMedication(
                id: UUID(),
                name: medName,
                dosage: nil,
                frequency: "Daily",
                reminderTime: nil,
                lastTakenDate: nil,
                todayStatus: "pending",
                dailyHistory: [:]
            )
        }

        if let encoded = try? JSONEncoder().encode(savedMeds) {
            UserDefaults.standard.set(encoded, forKey: "trackedMedications")
            print("✅ Saved \(selectedMeds.count) medications to local storage")
        }
    }
}
