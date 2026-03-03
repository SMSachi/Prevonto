//
//  AIChatView.swift
//  Prevonto
//
//  AI-powered health chat assistant
//

import SwiftUI

struct AIChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var suggestions: [String] = [
        "How is my heart rate trending?",
        "What can I do to improve my sleep?",
        "Analyze my health data from this week",
        "Give me tips for better energy levels"
    ]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeSection
                            }

                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Suggestions (show when no messages)
                if messages.isEmpty {
                    suggestionsSection
                }

                // Input area
                inputSection
            }
            .navigationTitle("Health Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: clearChat) {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var welcomeSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))

            Text("Hi! I'm your health assistant")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.404, green: 0.420, blue: 0.455))

            Text("Ask me anything about your health data, trends, or get personalized recommendations.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            sendMessage(suggestion)
                        }) {
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.36, green: 0.55, blue: 0.37).opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
    }

    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Ask about your health...", text: $inputText)
                .padding(12)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(24)

            Button(action: {
                sendMessage(inputText)
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(inputText.isEmpty ? .gray : Color(red: 0.36, green: 0.55, blue: 0.37))
            }
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }

    // MARK: - Actions

    private func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        Task {
            do {
                let response = try await AIAgentAPI.shared.chat(message: text)

                await MainActor.run {
                    let assistantMessage = ChatMessage(role: .assistant, content: response.response)
                    messages.append(assistantMessage)
                    isLoading = false

                    // Update suggestions if provided
                    if let newSuggestions = response.suggestions, !newSuggestions.isEmpty {
                        suggestions = newSuggestions
                    }
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        content: "I'm sorry, I couldn't process your request. Please try again later."
                    )
                    messages.append(errorMessage)
                    isLoading = false
                    print("Chat error: \(error)")
                }
            }
        }
    }

    private func clearChat() {
        messages = []
        suggestions = [
            "How is my heart rate trending?",
            "What can I do to improve my sleep?",
            "Analyze my health data from this week",
            "Give me tips for better energy levels"
        ]
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()

    enum MessageRole {
        case user
        case assistant
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.role == .user
                            ? Color(red: 0.36, green: 0.55, blue: 0.37)
                            : Color(red: 0.96, green: 0.97, blue: 0.98)
                    )
                    .cornerRadius(20)

                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(y: dotOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: dotOffset
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(20)
        .onAppear {
            dotOffset = -5
        }
    }
}

// MARK: - Preview

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
}
