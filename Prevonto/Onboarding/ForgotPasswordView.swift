//
//  ForgotPasswordView.swift
//  Prevonto
//
//  Password reset flow
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

                // Title
                Text("Reset Password")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

                // Description
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if showSuccess {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Email Sent!")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Check your inbox for a password reset link. It may take a few minutes to arrive.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Back to Login")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                } else {
                    // Email input
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(Rectangle().frame(height: 1).padding(.top, 43), alignment: .top)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 24)

                        if let error = errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                        }

                        // Submit button
                        Button(action: {
                            sendResetEmail()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                                    .cornerRadius(12)
                            } else {
                                Text("Send Reset Link")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(email.isEmpty ? Color.gray : Color(red: 0.01, green: 0.33, blue: 0.18))
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(email.isEmpty || isLoading)
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private func sendResetEmail() {
        guard !email.isEmpty else { return }

        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await AuthAPI.shared.forgotPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Show success anyway to prevent email enumeration
                    showSuccess = true
                }
            }
        }
    }
}

// MARK: - Preview

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
