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

        Task {
            do {
                let profile = try await SettingsAPI.shared.getProfile()
                await MainActor.run {
                    if let name = profile.full_name {
                        fullName = name
                    }
                    if let emailAddress = profile.email {
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
                    // Keep default values on error
                }
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

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
