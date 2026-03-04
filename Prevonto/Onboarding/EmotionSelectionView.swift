// Onboarding page 6 out of 9 prompts user for their current emotion (when they first signed up an account)
import SwiftUI

struct EmotionSelectionView: View {
    @State private var selectedEmotionIndex = 2
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    let emotions: [(description: String, apiValue: String)] = [
        ("exhausted", "exhausted"),
        ("a bit down", "down"),
        ("neutral", "neutral"),
        ("content", "content"),
        ("happy", "happy")
    ]

    var body: some View {
        OnboardingStepWrapper(step: step, title: "How do you feel\nright now?") {
            VStack(spacing: 24) {
                Spacer()

                // Emotion icons - geometric robot faces
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedEmotionIndex = index
                            }
                        }) {
                            MoodFaceView(
                                moodIndex: index,
                                isSelected: selectedEmotionIndex == index
                            )
                        }
                    }
                }

                // Description below icons
                Text("I'm feeling \(emotions[selectedEmotionIndex].description).")
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
                try await OnboardingAPI.shared.saveMood(emotions[selectedEmotionIndex].1)
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

// Custom geometric robot face view matching the Figma design
struct MoodFaceView: View {
    let moodIndex: Int
    let isSelected: Bool

    private var size: CGFloat {
        isSelected ? 64 : 52
    }

    private var backgroundColor: Color {
        isSelected ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.gray.opacity(0.2)
    }

    private var faceColor: Color {
        isSelected ? .white : Color.gray.opacity(0.6)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .frame(width: size, height: size)

            // Draw the face based on mood index
            VStack(spacing: isSelected ? 8 : 6) {
                // Eyes
                HStack(spacing: isSelected ? 12 : 10) {
                    eyeView(for: moodIndex)
                    eyeView(for: moodIndex)
                }

                // Mouth
                mouthView(for: moodIndex)
            }
        }
    }

    @ViewBuilder
    private func eyeView(for index: Int) -> some View {
        let eyeSize: CGFloat = isSelected ? 10 : 8

        switch index {
        case 0: // Exhausted - X eyes
            ZStack {
                Rectangle()
                    .fill(faceColor)
                    .frame(width: eyeSize, height: 2)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(faceColor)
                    .frame(width: eyeSize, height: 2)
                    .rotationEffect(.degrees(-45))
            }
            .frame(width: eyeSize, height: eyeSize)

        case 1: // Down - square sad eyes
            RoundedRectangle(cornerRadius: 2)
                .fill(faceColor)
                .frame(width: eyeSize, height: eyeSize)

        case 2: // Neutral - dash/line eyes
            RoundedRectangle(cornerRadius: 1)
                .fill(faceColor)
                .frame(width: eyeSize, height: 3)

        case 3: // Content - square eyes
            RoundedRectangle(cornerRadius: 2)
                .fill(faceColor)
                .frame(width: eyeSize, height: eyeSize)

        case 4: // Happy - curved happy eyes (upside down arcs)
            HappyEyeShape()
                .stroke(faceColor, lineWidth: 2)
                .frame(width: eyeSize, height: eyeSize / 2)

        default:
            Circle()
                .fill(faceColor)
                .frame(width: eyeSize, height: eyeSize)
        }
    }

    @ViewBuilder
    private func mouthView(for index: Int) -> some View {
        let mouthWidth: CGFloat = isSelected ? 20 : 16

        switch index {
        case 0, 1, 2: // Flat mouth for exhausted, down, neutral
            RoundedRectangle(cornerRadius: 1)
                .fill(faceColor)
                .frame(width: mouthWidth, height: 3)

        case 3: // Content - slight smile
            SmileMouthShape()
                .stroke(faceColor, lineWidth: 2.5)
                .frame(width: mouthWidth, height: 6)

        case 4: // Happy - bigger smile
            SmileMouthShape()
                .stroke(faceColor, lineWidth: 2.5)
                .frame(width: mouthWidth, height: 8)

        default:
            RoundedRectangle(cornerRadius: 1)
                .fill(faceColor)
                .frame(width: mouthWidth, height: 3)
        }
    }
}

// Custom shape for happy curved eyes
struct HappyEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

// Custom shape for smile mouth
struct SmileMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}
