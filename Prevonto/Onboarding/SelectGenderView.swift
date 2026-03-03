// Onboarding page 1 out of 9 prompts user for their gender
import SwiftUI

struct SelectGenderView: View {
    let next: () -> Void
    let back: () -> Void
    let step: Int

    @State private var selectedGender: String? = nil
    @State private var isSaving = false

    let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]

    var body: some View {
        OnboardingStepWrapper(step: step, title: "What is your gender?") {
            VStack(spacing: 16) {
                // Option buttons for user to select their gender
                ForEach(genderOptions, id: \.self) { gender in
                    Button(action: {
                        selectedGender = gender
                    }) {
                        HStack {
                            Text(gender)
                                .foregroundColor(selectedGender == gender ? .white : Color(red: 0.18, green: 0.2, blue: 0.38))
                            Spacer()
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                                    .background(
                                        Circle().fill(selectedGender == gender ? .white : Color.clear)
                                    )
                                    .frame(width: 20, height: 20)

                                if selectedGender == gender {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                                        .font(.system(size: 10, weight: .bold))
                                }
                            }
                        }
                        .padding()
                        .background(selectedGender == gender ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }

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
            .disabled(selectedGender == nil || isSaving)
        }.navigationBarBackButtonHidden(true)
    }

    private func saveAndContinue() {
        guard let gender = selectedGender else { return }
        isSaving = true

        Task {
            do {
                try await OnboardingAPI.shared.saveGender(gender.lowercased().replacingOccurrences(of: " ", with: "_"))
                await MainActor.run {
                    isSaving = false
                    next()
                }
            } catch {
                print("❌ Failed to save gender: \(error)")
                await MainActor.run {
                    isSaving = false
                    next()
                }
            }
        }
    }
}
