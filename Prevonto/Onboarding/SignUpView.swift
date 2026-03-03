// This is the Sign Up / Login page!
import SwiftUI

struct SignUpView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var acceptedTerms = false
    @State private var navigateToOnboarding = false
    @State private var navigateToDashboard = false

    @State private var showValidationMessage = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isNewUser = true  // Toggle between signup/login mode
    @State private var showForgotPassword = false
    
    let healthQuotes = [
        "Prevention is better than care.",
        "Health is wealth.",
        "Take care of your body. It's the only place you have to live.",
        "Your health is an investment, not an expense.",
        "In health there is freedom. Health is the first of all liberties."
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()

                Text(isNewUser ? "Let's get Started" : "Welcome Back")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                    .padding(.bottom, 0)

                AnimatedQuoteView(quotes: healthQuotes)
                    .frame(height: 40)
                    .padding(.top, 0)
                    .padding(.bottom, 24)

                // Only show Full Name for new users
                if isNewUser {
                    TextField("Full Name", text: $fullName)
                        .padding(.horizontal)
                        .frame(height: 44)
                        .background(Color.white)
                        .overlay(Rectangle().frame(height: 1).padding(.top, 43), alignment: .top)
                        .foregroundColor(.gray)
                }
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 43), alignment: .top)
                    .foregroundColor(.gray)
                
                SecureField("Password", text: $password)
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 43), alignment: .top)
                    .foregroundColor(.gray)
                
                // Only show Confirm Password for new users
                if isNewUser {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding(.horizontal)
                        .frame(height: 44)
                        .background(Color.white)
                        .overlay(Rectangle().frame(height: 1).padding(.top, 43), alignment: .top)
                        .foregroundColor(.gray)
                }

                // Only show terms for new users
                if isNewUser {
                    Toggle(isOn: $acceptedTerms) {
                        Text("By continuing you accept our Privacy Policy and Term of Use")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.top, 8)
                } else {
                    // Forgot password link for login mode
                    HStack {
                        Spacer()
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                        }
                    }
                    .padding(.top, 4)
                }

                if showValidationMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Navigation for new users -> Onboarding
                NavigationLink(destination: OnboardingFlowView(), isActive: $navigateToOnboarding) {
                    EmptyView()
                }
                
                // Navigation for returning users -> Dashboard
                NavigationLink(destination: ContentView(), isActive: $navigateToDashboard) {
                    EmptyView()
                }

                // Main action button
                Button(action: {
                    if isNewUser {
                        registerUser()
                    } else {
                        loginUser()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                            .cornerRadius(12)
                    } else {
                        Text(isNewUser ? "Join" : "Log In")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading)

                // Toggle between Login and Sign Up
                Button(action: {
                    withAnimation {
                        isNewUser.toggle()
                        showValidationMessage = false
                        errorMessage = ""
                    }
                }) {
                    if isNewUser {
                        Text("Already have an account? **Log In**")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        Text("Don't have an account? **Sign Up**")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.light)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private func registerUser() {
        // Validate inputs
        if fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Please fill in all fields."
            showValidationMessage = true
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            showValidationMessage = true
            return
        }

        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters."
            showValidationMessage = true
            return
        }
        
        if !acceptedTerms {
            errorMessage = "Please accept the terms and conditions."
            showValidationMessage = true
            return
        }
        
        isLoading = true
        showValidationMessage = false
        
        Task {
            do {
                print("📤 Registering user: \(email)")

                // Clear any existing local data for fresh start
                AuthManager.shared.clearAllLocalData()

                try await AuthManager.shared.register(
                    email: email,
                    password: password,
                    fullName: fullName
                )
                print("✅ Registration successful!")

                await MainActor.run {
                    isLoading = false
                    navigateToOnboarding = true  // New users go to onboarding
                }
            } catch let error as APIError {
                print("❌ Registration failed: \(error)")
                await MainActor.run {
                    isLoading = false
                    if case .httpError(let code, let body) = error {
                        if code == 400 && (body.contains("already") || body.contains("registered")) {
                            errorMessage = "Email already registered. Please log in instead."
                        } else if code == 400 && body.contains("password") {
                            errorMessage = "Password must be at least 8 characters."
                        } else if code == 400 {
                            errorMessage = "Invalid input. Check email and password (8+ chars)."
                        } else {
                            errorMessage = "Registration failed. Please try again."
                        }
                    } else {
                        errorMessage = "Registration failed. Please try again."
                    }
                    showValidationMessage = true
                }
            } catch {
                print("❌ Registration failed: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Connection error. Check your internet."
                    showValidationMessage = true
                }
            }
        }
    }
    
    private func loginUser() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please enter email and password."
            showValidationMessage = true
            return
        }

        isLoading = true
        showValidationMessage = false

        Task {
            do {
                print("📤 Logging in: \(email)")
                try await AuthManager.shared.login(
                    email: email,
                    password: password
                )
                print("✅ Login successful!")

                // Check if onboarding is completed
                let onboardingCompleted = try await OnboardingAPI.shared.isOnboardingCompleted()

                await MainActor.run {
                    isLoading = false
                    if onboardingCompleted {
                        navigateToDashboard = true  // Completed onboarding -> dashboard
                    } else {
                        navigateToOnboarding = true  // Incomplete onboarding -> continue
                    }
                }
            } catch let error as APIError {
                print("❌ Login failed: \(error)")
                await MainActor.run {
                    isLoading = false
                    if case .httpError(let code, _) = error {
                        if code == 401 {
                            errorMessage = "Invalid email or password. Check your credentials."
                        } else if code == 404 {
                            errorMessage = "Account not found. Please sign up first."
                        } else {
                            errorMessage = "Login failed. Please try again."
                        }
                    } else {
                        errorMessage = "Login failed. Please try again."
                    }
                    showValidationMessage = true
                }
            } catch {
                print("❌ Login failed: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Connection error. Check your internet."
                    showValidationMessage = true
                }
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
        }
    }
}
