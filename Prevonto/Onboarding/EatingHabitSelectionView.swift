// Onboarding page 7 out of 9 prompts user for their current diet
import SwiftUI

struct EatingHabitSelectionView: View {
    @State private var selectedHabit: String? = "Mostly Vegetarian"
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    struct HabitOption: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
    }

    let habits: [HabitOption] = [
        .init(icon: "🍎", label: "Balanced Diet"),
        .init(icon: "🥕", label: "Mostly Vegetarian"),
        .init(icon: "🍖", label: "Low Carb"),
        .init(icon: "🌾", label: "Gluten Free"),
        .init(icon: "🌱", label: "Vegan"),
        .init(icon: "🥩", label: "Keto")
    ]

    var body: some View {
        OnboardingStepWrapper(step: step, title: "What does your current\ndiet look like?") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(habits) { habit in
                    Button(action: {
                        selectedHabit = habit.label
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(spacing: 4) {
                                Text(habit.icon)
                                    .font(.system(size: 26))
                                Text(habit.label)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                            }

                            Spacer()

                            if selectedHabit == habit.label {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedHabit == habit.label ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.white)
                        )
                        .foregroundColor(selectedHabit == habit.label ? .white : .black)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
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
