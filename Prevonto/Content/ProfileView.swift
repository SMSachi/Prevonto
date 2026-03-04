// Profile page for the user in Prevonto app
// User can change their full name, date of birth, profile picture (if any), mobile number, and email here, but not stored in any database yet.
import SwiftUI

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var dateOfBirth = Date()
    @State private var showingSaveAlert = false
    @State private var showingDatePicker = false

    // Onboarding data (read-only display)
    @State private var gender: String = ""
    @State private var weight: String = ""
    @State private var age: String = ""

    // Loading and error states
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Profile Content
                    ZStack {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Profile Photo Section
                                profilePhotoSection

                                // Basic Details Section
                                basicDetailsSection

                                // Health Profile Section (from onboarding)
                                healthProfileSection

                                // Contact Details Section
                                contactDetailsSection

                                // Save Button
                                saveButton

                                Spacer(minLength: 30)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                        }

                        if isLoading {
                            Color.white.opacity(0.7)
                            ProgressView("Loading profile...")
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
                .navigationBarHidden(true)
            }
        }
        .alert("Profile Saved", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("Your profile information has been saved successfully.")
        }
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker(
                    "Select Date of Birth",
                    selection: $dateOfBirth,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

                Button("Done") {
                    showingDatePicker = false
                }
                .font(.custom("Noto Sans", size: 16))
                .padding()
            }
        }
        .onAppear {
            loadProfile()
        }
    }

    // MARK: - API Functions
    private func loadProfile() {
        isLoading = true
        errorMessage = nil

        // First, load from local storage (immediate display)
        if let localName = AuthManager.shared.getUserFullName(), !localName.isEmpty {
            fullName = localName
        }
        if let localEmail = AuthManager.shared.getUserEmail(), !localEmail.isEmpty {
            email = localEmail
        }

        // Load onboarding data from local storage
        if let localGender = AuthManager.shared.getOnboardingGender() {
            gender = localGender
        }
        if let weightData = AuthManager.shared.getOnboardingWeight() {
            weight = "\(Int(weightData.weight)) \(weightData.unit)"
        }
        if let localAge = AuthManager.shared.getOnboardingAge() {
            age = "\(localAge) years"
        }

        // Then fetch from API to get latest data
        Task {
            do {
                let profile = try await SettingsAPI.shared.getProfile()
                await MainActor.run {
                    if let name = profile.full_name, !name.isEmpty {
                        fullName = name
                        // Update local storage with API data
                        AuthManager.shared.saveUserProfile(fullName: name, email: nil)
                    }
                    if let emailAddress = profile.email, !emailAddress.isEmpty {
                        email = emailAddress
                    }
                    if let phone = profile.phone_number {
                        mobileNumber = phone
                    }
                    if let dobString = profile.date_of_birth {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withFullDate]
                        if let date = formatter.date(from: dobString) {
                            dateOfBirth = date
                        }
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Keep local values on error
                }
            }

            // Also try to fetch onboarding data from API
            do {
                let onboarding = try await OnboardingAPI.shared.getOnboarding()
                await MainActor.run {
                    if let apiGender = onboarding.gender, !apiGender.isEmpty {
                        // Format gender for display (capitalize, replace underscores)
                        gender = apiGender.replacingOccurrences(of: "_", with: " ").capitalized
                        AuthManager.shared.saveOnboardingGender(gender)
                    }
                    if let apiWeight = onboarding.current_weight, apiWeight > 0 {
                        let unit = onboarding.weight_unit ?? "lbs"
                        weight = "\(Int(apiWeight)) \(unit)"
                        AuthManager.shared.saveOnboardingWeight(apiWeight, unit: unit)
                    }
                    if let apiAge = onboarding.age, apiAge > 0 {
                        age = "\(apiAge) years"
                        AuthManager.shared.saveOnboardingAge(apiAge)
                    }
                }
            } catch {
                // Keep local values on error
                print("⚠️ Failed to fetch onboarding data: \(error)")
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        errorMessage = nil

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dobString = formatter.string(from: dateOfBirth)

        Task {
            do {
                try await SettingsAPI.shared.updateProfile(
                    fullName: fullName.isEmpty ? nil : fullName,
                    email: email.isEmpty ? nil : email,
                    phoneNumber: mobileNumber.isEmpty ? nil : mobileNumber,
                    dateOfBirth: dobString
                )
                await MainActor.run {
                    // Also save to local storage so Settings shows updated name
                    AuthManager.shared.saveUserProfile(
                        fullName: fullName.isEmpty ? nil : fullName,
                        email: email.isEmpty ? nil : email
                    )
                    isSaving = false
                    showingSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save profile"
                }
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
                
                Text("My Profile")
                    .font(.custom("Noto Sans", size: 28))
                    .fontWeight(.black)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                
                Spacer()
                
                // Invisible spacer to balance the back button
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 0)
            .background(Color.white)
        }
    }
    
    // MARK: - Profile Photo Section
    var profilePhotoSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                // Profile Photo
                Circle()
                    .fill(Color(red: 0.86, green: 0.93, blue: 0.86))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    )
                
                // Photo upload into profile icon button here
                Button(action: {
                    // Profile photo upload functionality placeholder
                }) {
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
    
    var basicDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Details")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
            
            VStack(spacing: 20) {
                // Full Name
                ProfileInputField(
                    title: "Full Name",
                    text: $fullName,
                    placeholder: "Enter your full name"
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.custom("Noto Sans", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Text(dateFormatter.string(from: dateOfBirth))
                                .font(.custom("Noto Sans", size: 16))
                                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Health Profile Section
    var healthProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Profile")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))

            VStack(spacing: 12) {
                if !gender.isEmpty {
                    ProfileDisplayField(title: "Gender", value: gender)
                }
                if !weight.isEmpty {
                    ProfileDisplayField(title: "Weight", value: weight)
                }
                if !age.isEmpty {
                    ProfileDisplayField(title: "Age", value: age)
                }
                if gender.isEmpty && weight.isEmpty && age.isEmpty {
                    Text("Complete onboarding to see your health profile")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(.gray)
                        .italic()
                }
            }
        }
    }

    // MARK: - Contact Details Section
    var contactDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Details")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))

            VStack(spacing: 20) {
                // Phone Number
                ProfileInputField(
                    title: "Mobile Number",
                    text: $mobileNumber,
                    placeholder: "Enter your mobile number"
                )

                // Email
                ProfileInputField(
                    title: "Email",
                    text: $email,
                    placeholder: "Enter your email address"
                )
            }
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Save Button
    var saveButton: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                Text(error)
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(.red)
            }

            Button(action: {
                saveProfile()
            }) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isSaving ? "Saving..." : "Save")
                        .font(.custom("Noto Sans", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 0.02, green: 0.33, blue: 0.18))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isSaving)
        }
    }
    
    // MARK: - Date Formatter
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }
}

// MARK: - Profile Input Field Component
struct ProfileInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Noto Sans", size: 14))
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))

            TextField(placeholder, text: $text)
                .font(.custom("Noto Sans", size: 16))
                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                )
        }
    }
}

// MARK: - Profile Display Field Component (Read-only)
struct ProfileDisplayField: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Noto Sans", size: 14))
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))
            Spacer()
            Text(value)
                .font(.custom("Noto Sans", size: 16))
                .foregroundColor(Color(red: 0.18, green: 0.2, blue: 0.38))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
