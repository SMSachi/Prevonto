// Onboarding page 3 out of 9 prompts user for their age
import SwiftUI

struct AgeSelectionView: View {
    @State private var selectedAge: Int = 19
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    let ageRange = Array(13...100)

    var body: some View {
        OnboardingStepWrapper(step: step, title: "How old are you?") {
            VStack(spacing: 24) {
                // Picker for user to swipe or drag vertically to specific age user choose
                CenteredVerticalAgePicker(ages: ageRange, selectedAge: $selectedAge)

                // Next Button
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

    private func saveAndContinue() {
        isSaving = true

        Task {
            do {
                try await OnboardingAPI.shared.saveAge(selectedAge)
                await MainActor.run {
                    isSaving = false
                    next()
                }
            } catch {
                print("❌ Failed to save age: \(error)")
                await MainActor.run {
                    isSaving = false
                    next()
                }
            }
        }
    }
}

// Picker for user to swipe or drag vertically to specific age user choose
struct CenteredVerticalAgePicker: View {
    let ages: [Int]
    @Binding var selectedAge: Int

    let itemHeight: CGFloat = 48
    let spacing: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let totalHeight = itemHeight + spacing
            let centerY = geo.frame(in: .global).midY

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: spacing) {
                        ForEach(ages, id: \.self) { age in
                            AgeRow(age: age,
                                   selectedAge: $selectedAge,
                                   centerY: centerY,
                                   itemHeight: itemHeight,
                                   totalHeight: totalHeight)
                                .id(age)
                        }
                    }
                    .padding(.vertical, (geo.size.height - itemHeight) / 2)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            proxy.scrollTo(selectedAge, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(height: 240)
    }
}

// Display each age number for user to can select
struct AgeRow: View {
    let age: Int
    @Binding var selectedAge: Int
    let centerY: CGFloat
    let itemHeight: CGFloat
    let totalHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let itemCenterY = geo.frame(in: .global).midY
            let isSelected = abs(itemCenterY - centerY) < totalHeight / 2

            Text("\(age)")
                .font(.system(size: isSelected ? 22 : 18, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                .padding(.horizontal, isSelected ? 32 : 0)
                .frame(height: itemHeight)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.clear
                )
                .cornerRadius(isSelected ? 16 : 0)
                .shadow(color: isSelected ? Color.green.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                .onAppear {
                    if isSelected {
                        selectedAge = age
                    }
                }
        }
        .frame(height: itemHeight)
    }
}
