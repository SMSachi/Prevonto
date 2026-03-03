// Onboarding page 6 out of 9 prompts user for their current emotion (when they first signed up an account)
import SwiftUI

struct EmotionSelectionView: View {
    @State private var selectedEmotionIndex = 2
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    let emotions: [(icon: String, description: String, apiValue: String)] = [
        ("😫", "exhausted", "exhausted"),
        ("☹️", "a bit down", "down"),
        ("😐", "neutral", "neutral"),
        ("🙂", "content", "content"),
        ("😄", "happy", "happy")
    ]

    var body: some View {
        OnboardingStepWrapper(step: step, title: "How do you feel\nright now?") {
            VStack(spacing: 24) {
                // Emotion icons
                HStack(spacing: 16) {
                    ForEach(emotions.indices, id: \.self) { index in
                        Button(action: {
                            selectedEmotionIndex = index
                        }) {
                            Text(emotions[index].icon)
                                .font(.system(size: 32))
                                .frame(width: 56, height: 56)
                                .background(
                                    selectedEmotionIndex == index
                                    ? Color(red: 0.39, green: 0.59, blue: 0.38)
                                    : Color.gray.opacity(0.15)
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: selectedEmotionIndex == index ? Color.green.opacity(0.3) : .clear,
                                        radius: 8, x: 0, y: 4)
                        }
                    }
                }

                // Description below icons
                Text("I’m feeling \(emotions[selectedEmotionIndex].description).")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.2))

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

                Spacer()
            }
        }
    }

    private func saveAndContinue() {
        isSaving = true

        Task {
            do {
                try await OnboardingAPI.shared.saveMood(emotions[selectedEmotionIndex].apiValue)
                await MainActor.run {
                    isSaving = false
                    next()
                }
            } catch {
                print("❌ Failed to save mood: \(error)")
                await MainActor.run {
                    isSaving = false
                    next()
                }
            }
        }
    }
}
