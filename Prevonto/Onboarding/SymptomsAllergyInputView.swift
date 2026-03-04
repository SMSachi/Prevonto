// Onboarding page 9 out of 9 prompts user for any and all allergies they have
import SwiftUI

struct SymptomsAllergyInputView: View {
    @State private var selectedSymptoms: Set<String> = []
    @State private var allergyDetails: Set<String> = []
    @State private var isSaving = false
    @State private var symptomSearchQuery: String = ""
    @State private var allergySearchQuery: String = ""
    @State private var customSymptoms: [String] = []
    @State private var customAllergies: [String] = []

    let next: () -> Void
    let back: () -> Void
    let step: Int

    let commonSymptoms = ["Cough", "Fever", "Headache", "Flu", "Muscle fatigue", "Shortness of breath"]
    let commonAllergies = ["Peanuts", "Tree nuts", "Milk", "Eggs", "Wheat", "Soy", "Fish", "Shellfish", "Sesame", "Penicillin", "Sulfa", "Aspirin", "Latex", "Pollen", "Dust mites", "Mold", "Pet dander", "Bee stings"]

    // All symptoms including custom ones
    var allSymptoms: [String] {
        commonSymptoms + customSymptoms
    }

    // Filtered symptoms based on search
    var filteredSymptoms: [String] {
        if symptomSearchQuery.isEmpty {
            return allSymptoms
        }
        return allSymptoms.filter { $0.lowercased().contains(symptomSearchQuery.lowercased()) }
    }

    // Check if can add custom symptom
    var canAddCustomSymptom: Bool {
        let trimmed = symptomSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !allSymptoms.contains(where: { $0.lowercased() == trimmed.lowercased() })
    }

    // Filtered allergies based on search
    var filteredAllergies: [String] {
        let allAllergies = commonAllergies + customAllergies
        if allergySearchQuery.isEmpty {
            return allAllergies
        }
        return allAllergies.filter { $0.lowercased().contains(allergySearchQuery.lowercased()) }
    }

    // Check if can add custom allergy
    var canAddCustomAllergy: Bool {
        let trimmed = allergySearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let allAllergies = commonAllergies + customAllergies
        return !trimmed.isEmpty && !allAllergies.contains(where: { $0.lowercased() == trimmed.lowercased() })
    }

    var body: some View {
        OnboardingStepWrapper(step: step, title: "Do you have any\nsymptoms or allergies?") {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Symptoms section
                    Text("Symptoms")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    // Symptom search bar with add button
                    HStack(spacing: 8) {
                        HStack {
                            TextField("Search or add symptom", text: $symptomSearchQuery)
                                .padding(.vertical, 8)
                                .padding(.leading, 12)
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                        .frame(height: 44)

                        if canAddCustomSymptom {
                            Button(action: addCustomSymptom) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.39, green: 0.59, blue: 0.38))
                            }
                        }
                    }

                    // Show hint to add custom symptom
                    if canAddCustomSymptom {
                        Text("Tap + to add \"\(symptomSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Symptom tags
                    TagFlowLayout(tags: filteredSymptoms, selection: $selectedSymptoms)
                        .frame(minHeight: 80)

                    // Allergy section
                    Text("Allergies")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)

                    // Allergy search bar with add button
                    HStack(spacing: 8) {
                        HStack {
                            TextField("Search or add allergy", text: $allergySearchQuery)
                                .padding(.vertical, 8)
                                .padding(.leading, 12)
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                        .frame(height: 44)

                        if canAddCustomAllergy {
                            Button(action: addCustomAllergy) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.39, green: 0.59, blue: 0.38))
                            }
                        }
                    }

                    // Show hint to add custom allergy
                    if canAddCustomAllergy {
                        Text("Tap + to add \"\(allergySearchQuery.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Allergy tags
                    TagFlowLayout(tags: filteredAllergies, selection: $allergyDetails)
                        .frame(minHeight: 80)

                    Spacer(minLength: 20)

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
    }

    private func addCustomSymptom() {
        let trimmed = symptomSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !allSymptoms.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            customSymptoms.append(trimmed)
            selectedSymptoms.insert(trimmed)
            symptomSearchQuery = ""
        }
    }

    private func addCustomAllergy() {
        let trimmed = allergySearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let allAllergies = commonAllergies + customAllergies
        if !trimmed.isEmpty && !allAllergies.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            customAllergies.append(trimmed)
            allergyDetails.insert(trimmed)
            allergySearchQuery = ""
        }
    }

    private func saveAndContinue() {
        isSaving = true

        // Combine symptoms and allergies into a single string for the API
        var parts: [String] = []

        if !selectedSymptoms.isEmpty {
            parts.append("Symptoms: \(selectedSymptoms.sorted().joined(separator: ", "))")
        }

        if !allergyDetails.isEmpty {
            parts.append("Allergies: \(allergyDetails.sorted().joined(separator: ", "))")
        }

        let combinedData = parts.joined(separator: "; ")

        Task {
            do {
                try await OnboardingAPI.shared.saveSymptoms(combinedData)
                await MainActor.run {
                    isSaving = false
                    next()
                }
            } catch {
                print("❌ Failed to save symptoms/allergies: \(error)")
                await MainActor.run {
                    isSaving = false
                    next()
                }
            }
        }
    }
}

struct TagFlowLayout: View {
    let tags: [String]
    @Binding var selection: Set<String>
    var onTap: ((String) -> Void)? = nil

    var body: some View {
        FlexibleView(data: tags, spacing: 8, alignment: .leading) { tag in
            TagPill(label: tag, selected: selection.contains(tag)) {
                if selection.contains(tag) {
                    selection.remove(tag)
                } else {
                    selection.insert(tag)
                }
                onTap?(tag)
            }
        }
    }
}


struct TagPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.footnote)
                    .foregroundColor(selected ? .white : .primary)
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? Color(red: 0.39, green: 0.59, blue: 0.38) : Color.gray.opacity(0.15))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    init(data: Data, spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var rows: [[Data.Element]] = [[]]

        for item in data {
            let itemView = UIHostingController(rootView: content(item)).view!
            let itemSize = itemView.intrinsicContentSize

            if width + itemSize.width + spacing > geometry.size.width {
                width = 0
                height += itemSize.height + spacing
                rows.append([item])
            } else {
                rows[rows.count - 1].append(item)
            }
            width += itemSize.width + spacing
        }

        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }
}
