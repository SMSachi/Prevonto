//
//  ChangePasswordView.swift
//  Prevonto
//
//  Change password for logged-in users
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 50))
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))

                    Text("Change Password")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))

                    Text("Enter your current password and choose a new one.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                if showSuccess {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Password Changed!")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Your password has been updated successfully.")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(red: 0.36, green: 0.55, blue: 0.37))
                                .cornerRadius(12)
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Password form
                    VStack(spacing: 20) {
                        // Current Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))

                            SecureField("Enter current password", text: $currentPassword)
                                .padding()
                                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                .cornerRadius(12)
                        }

                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))

                            SecureField("Enter new password", text: $newPassword)
                                .padding()
                                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                .cornerRadius(12)

                            // Password requirements
                            VStack(alignment: .leading, spacing: 4) {
                                PasswordRequirementRow(
                                    text: "At least 8 characters",
                                    isMet: newPassword.count >= 8
                                )
                                PasswordRequirementRow(
                                    text: "Contains a number",
                                    isMet: newPassword.contains(where: { $0.isNumber })
                                )
                                PasswordRequirementRow(
                                    text: "Contains uppercase letter",
                                    isMet: newPassword.contains(where: { $0.isUppercase })
                                )
                            }
                            .padding(.top, 4)
                        }

                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))

                            SecureField("Confirm new password", text: $confirmPassword)
                                .padding()
                                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                .cornerRadius(12)

                            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Submit button
                        Button(action: {
                            changePassword()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(red: 0.36, green: 0.55, blue: 0.37))
                                    .cornerRadius(12)
                            } else {
                                Text("Update Password")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(isFormValid ? Color(red: 0.36, green: 0.55, blue: 0.37) : Color.gray)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword.contains(where: { $0.isNumber }) &&
        newPassword.contains(where: { $0.isUppercase }) &&
        newPassword == confirmPassword
    }

    private func changePassword() {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await AuthAPI.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch let error as APIError {
                await MainActor.run {
                    isLoading = false
                    switch error {
                    case .httpError(let code, _):
                        if code == 401 {
                            errorMessage = "Current password is incorrect."
                        } else {
                            errorMessage = "Failed to change password. Please try again."
                        }
                    default:
                        errorMessage = "Failed to change password. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to change password. Please try again."
                }
            }
        }
    }
}

// MARK: - Password Requirement Row

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .green : .gray)

            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .green : .gray)
        }
    }
}

// MARK: - Preview

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChangePasswordView()
        }
    }
}
