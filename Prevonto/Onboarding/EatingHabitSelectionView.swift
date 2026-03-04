// Onboarding page 7 out of 9 prompts user for their current diet
import SwiftUI

struct EatingHabitSelectionView: View {
    @State private var selectedHabit: String? = nil
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    struct HabitOption: Identifiable {
        let id = UUID()
        let icon: String  // SF Symbol name
        let label: String
    }

    let habits: [HabitOption] = [
        .init(icon: "leaf.circle.fill", label: "Balanced Diet"),
        .init(icon: "carrot.fill", label: "Mostly Vegetarian"),
        .init(icon: "fork.knife", label: "Low Carb"),
        .init(icon: "leaf.arrow.triangle.circlepath", label: "Gluten Free"),
        .init(icon: "leaf.fill", label: "Vegan"),
        .init(icon: "flame.fill", label: "Keto")
    ]

    var body: some View {
        OnboardingStepWrapper(step: step, title: "What does your current\ndiet look like?") {
            VStack(spacing: 16) {
                // Main diet options in 2-column grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(habits) { habit in
                        Button(action: {
                            selectedHabit = habit.label
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: habit.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedHabit == habit.label ? .white : Color(red: 0.39, green: 0.59, blue: 0.38))
                                Text(habit.label)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedHabit == habit.label ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.white)
                            )
                            .foregroundColor(selectedHabit == habit.label ? .white : .black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedHabit == habit.label ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }

                // "Other" option - full width rectangle at bottom
                Button(action: {
                    selectedHabit = "Other"
                }) {
                    HStack {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectedHabit == "Other" ? .white : Color(red: 0.39, green: 0.59, blue: 0.38))
                        Text("Other")
                            .font(.subheadline)
                        Spacer()
                        if selectedHabit == "Other" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedHabit == "Other" ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.white)
                    )
                    .foregroundColor(selectedHabit == "Other" ? .white : .black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedHabit == "Other" ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            }

            Spacer()

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
            .disabled(selectedHabit == nil || isSaving)
        }
    }

    private func saveAndContinue() {
        guard let habit = selectedHabit else { return }
        isSaving = true

        Task {
            do {
                try await OnboardingAPI.shared.saveDiet(habit.lowercased().replacingOccurrences(of: " ", with: "_"))
                await MainActor.run {
                    isSaving = false
                    next()
                }
            } catch {
                print("❌ Failed to save diet: \(error)")
                await MainActor.run {
                    isSaving = false
                    next()
                }
            }
        }
    }
}
