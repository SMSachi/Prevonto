// Onboarding page 5 out of 9 prompts user for their level amount of sleep
import SwiftUI

struct SleepLevelSelectionView: View {
    @State private var selectedLevel: Int? = nil
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    struct SleepOption: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let apiValue: String
    }

    let sleepOptions: [SleepOption] = [
        .init(id: 1, title: "Very Low", subtitle: "~0–3hr daily", apiValue: "very_low"),
        .init(id: 2, title: "Low", subtitle: "~3–5hr daily", apiValue: "low"),
        .init(id: 3, title: "Moderate", subtitle: "~5–8hr daily", apiValue: "moderate"),
        .init(id: 4, title: "High", subtitle: "~8–10hr daily", apiValue: "high"),
        .init(id: 5, title: "Excellent", subtitle: "10+ hr daily", apiValue: "excellent")
    ]

    var body: some View {
        OnboardingStepWrapper(step: step, title: "What is your current\nsleep level?") {
            VStack(spacing: 20) {
                ForEach(sleepOptions) { option in
                    Button(action: {
                        selectedLevel = option.id
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .fontWeight(.semibold)
                                Text(option.subtitle)
                                    .font(.caption)
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                                    .background(
                                        Circle().fill(selectedLevel == option.id ? .white : Color.clear)
                                    )
                                    .frame(width: 20, height: 20)

                                if selectedLevel == option.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                                        .font(.system(size: 10, weight: .bold))
                                }
                            }
                        }
                        .padding()
                        .background(selectedLevel == option.id ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.white)
                        .foregroundColor(selectedLevel == option.id ? .white : .black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
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
                .disabled(selectedLevel == nil || isSaving)
            }
        }
    }

    private func saveAndContinue() {
        guard let level = selectedLevel,
              let option = sleepOptions.first(where: { $0.id == level }) else { return }
        isSaving = true

        Task {
            do {
                try await OnboardingAPI.shared.saveSleepLevel(option.apiValue)
                await MainActor.run {
                    isSaving = false
                    next()
                }
            } catch {
                print("❌ Failed to save sleep level: \(error)")
                await MainActor.run {
                    isSaving = false
                    next()
                }
            }
        }
    }
}
