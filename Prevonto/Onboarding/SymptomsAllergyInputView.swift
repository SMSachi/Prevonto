// Onboarding page 9 out of 9 prompts user for any and all allergies they have
import SwiftUI

struct SymptomsAllergyInputView: View {
    @State private var selectedSymptoms: Set<String> = ["Fever"]
    @State private var selectedAllergyCategory: String? = "Food"
    @State private var showAllergyDetails = false
    @State private var allergyDetails: Set<String> = ["Gluten"]
    @State private var allergyDescription: String = ""
    @State private var isSaving = false

    let next: () -> Void
    let back: () -> Void
    let step: Int

    let commonSymptoms = ["Cough", "Fever", "Headache", "Flu", "Muscle fatigue", "Shortness of breath"]
    let allergyCategories = ["Food", "Indoor", "Seasonal", "Drug", "Skin", "Other"]
    let additionalAllergyTags = ["Dairy", "Gluten", "Soy", "Shellfish", "Nuts"]

    var body: some View {
        OnboardingStepWrapper(step: step, title: "Do you have any\nsymptoms or allergies?") {
            VStack(alignment: .leading, spacing: 24) {
                // Symptoms section
                Text("Symptoms")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                TagFlowLayout(tags: commonSymptoms.prefix(5).map { String($0) }, selection: $selectedSymptoms)

                HStack {
                    TagPill(label: "+4", selected: false, action: {})
                    Spacer()
                }

                HStack {
                    TextField("Search", text: .constant(""))
                        .disabled(true)
                        .padding(.vertical, 8)
                        .padding(.leading, 12)
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.trailing, 12)
                }
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                .frame(height: 44)

                // Allergy section
                Text("Allergies")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                TagFlowLayout(tags: allergyCategories, selection: .init(
                    get: { selectedAllergyCategory.map { [$0] } ?? [] },
                    set: { selectedAllergyCategory = $0.first }
                )) {
                    if $0 == "Food" {
                        showAllergyDetails = true
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
                .disabled(isSaving)
            }
            .sheet(isPresented: $showAllergyDetails) {
                AllergyDetailModal(selectedTags: $allergyDetails, description: $allergyDescription)
            }
        }
    }

    private func saveAndContinue() {
        isSaving = true

        // Combine symptoms and allergies into a single string for the API
        var parts: [String] = []

        if !selectedSymptoms.isEmpty {
            parts.append("Symptoms: \(selectedSymptoms.joined(separator: ", "))")
        }

        if let category = selectedAllergyCategory {
            var allergyPart = "Allergies (\(category))"
            if !allergyDetails.isEmpty {
                allergyPart += ": \(allergyDetails.joined(separator: ", "))"
            }
            if !allergyDescription.isEmpty {
                allergyPart += " - \(allergyDescription)"
            }
            parts.append(allergyPart)
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

struct AllergyDetailModal: View {
    @Binding var selectedTags: Set<String>
    @Binding var description: String

    let tags = ["Dairy", "Gluten", "Soy", "Shellfish", "Nuts"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Please add additional details\nregarding your food allergy")
                .font(.headline)
                .multilineTextAlignment(.center)

            TagFlowLayout(tags: tags, selection: $selectedTags)

            TextEditor(text: $description)
                .frame(height: 100)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Text("Save")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                    .cornerRadius(12)
            }
        }
        .padding()
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
