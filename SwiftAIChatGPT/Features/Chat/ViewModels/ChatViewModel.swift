//
//
// SwiftAIChatGPT
// ChatViewModel.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import SwiftData

@Observable
class ChatViewModel {
    var messageText = ""
    var isThinking = false
    var streamingMessage: Message?
    var streamingText = ""
    private(set) var conversation: Conversation
    
    // Dependencies
    private let messageManager: MessageManager
    private let networkService: NetworkService
    let networkMonitor: NetworkMonitor
    private let errorHandler: (AppError) -> Void
    
    // Sample mock responses (moved from earlier implementation)
    private let mockResponses = [
        // Simple responses with proper spacing
        "I understand your question. Let me help you with that.",
        
        "That's an interesting point! Here's what I think about it.",
        
        // Bold and italic with proper spacing
        "This topic requires **careful consideration**. Let me explain why *emphasis* on proper implementation matters.",
        
        // Lists with proper spacing and formatting
        "Here are some key points to consider:\n\n1. First, establish your requirements clearly\n2. Second, design your architecture thoughtfully\n3. Finally, implement with attention to detail",
        
        "The main benefits include:\n\n- Improved user experience\n- Better performance\n- Easier maintenance\n- Greater scalability",
        
        // Headings with proper spacing
        "# Swift Programming Basics\n\nSwift is a powerful language for iOS development.\n\n## Key Features\n\n- Type safety\n- Optionals\n- Protocol-oriented design\n- Modern syntax",
        
        // Code blocks with better examples
        "Here's how you would implement a custom view modifier in SwiftUI:\n\n```swift\nstruct RoundedButtonStyle: ViewModifier {\n    var backgroundColor: Color\n    var cornerRadius: CGFloat\n    \n    func body(content: Content) -> some View {\n        content\n            .padding(.horizontal, 20)\n            .padding(.vertical, 10)\n            .background(backgroundColor)\n            .cornerRadius(cornerRadius)\n            .foregroundColor(.white)\n            .shadow(radius: 3)\n    }\n}\n\n// Usage\nButton(\"Save\") {\n    saveData()\n}\n.modifier(RoundedButtonStyle(backgroundColor: .blue, cornerRadius: 10))\n```\n\nThis creates a reusable button style for your application.",
        
        // Blockquotes with proper spacing
        "As noted in Apple's documentation:\n\n> SwiftUI provides views, controls, and layout structures for declaring your app's user interface. The framework provides event handlers for delivering taps, gestures, and other types of input, and tools to manage the flow of data from your app's models down to the views and controls that users see and interact with.\n\nThis approach simplifies UI development.",
        
        // Links with proper formatting
        "For more information, check the [Swift documentation](https://swift.org/documentation/) or visit [Apple's SwiftUI tutorials](https://developer.apple.com/tutorials/swiftui/)."
    ]
    
    init(
        conversation: Conversation,
        modelContext: ModelContext,
        networkMonitor: NetworkMonitor,
        networkService: NetworkService,
        errorHandler: @escaping (AppError) -> Void
    ) {
        self.conversation = conversation
        self.networkMonitor = networkMonitor
        self.networkService = networkService
        self.errorHandler = errorHandler
        self.messageManager = MessageManager(
            modelContext: modelContext,
            errorHandler: errorHandler
        )
    }
    
    // Convenience initializer for backward compatibility
    convenience init(
        conversation: Conversation,
        modelContext: ModelContext,
        networkMonitor: NetworkMonitor,
        errorHandler: @escaping (AppError) -> Void
    ) {
        self.init(
            conversation: conversation,
            modelContext: modelContext,
            networkMonitor: networkMonitor,
            networkService: NetworkService(networkMonitor: networkMonitor),
            errorHandler: errorHandler
        )
    }
    
    @MainActor
    func sendMessage() async {
        guard !messageText.isEmpty else { return }
        
        // Check network connectivity
        guard networkMonitor.isConnected else {
            errorHandler(.networkUnavailable)
            return
        }
        
        // Haptic feedback
        HapticService.tick()
        
        // Create and add user message
        let userMessageContent = messageText
        let userMessage = Message(content: userMessageContent, isUser: true)
        
        // Add the message to the conversation through the manager
        messageManager.addMessage(userMessage, to: conversation)
        
        // Update conversation title if needed
        messageManager.updateConversationTitle(conversation, with: userMessageContent)
        
        // Clear input immediately after creating the message
        messageText = ""
        
        // Show thinking state
        isThinking = true
        
        // Clear any existing streaming message
        streamingMessage = nil
        streamingText = ""
        
        // Get AI response
        await fetchAIResponse(for: userMessageContent)
    }
    
    private func fetchAIResponse(for userInput: String) async {
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Check if still connected
            guard networkMonitor.isConnected else {
                await MainActor.run {
                    isThinking = false
                    errorHandler(.networkUnavailable)
                }
                return
            }
            
            // Fetch response from network service or fall back to mock
            let responseText: String
            
            // For now, just use mock responses since we don't have a real API
            // In the future, we would use: try await networkService.fetchAIResponse(prompt: userInput)
            responseText = mockResponses.randomElement() ?? "I'm here to help!"
            
            // Process response on main actor
            await MainActor.run {
                isThinking = false
                HapticService.tick()
                createStreamingMessage(with: responseText)
            }
        } catch {
            await MainActor.run {
                isThinking = false
                if error is CancellationError {
                    errorHandler(.timeout)
                } else {
                    errorHandler(.apiError("Unable to get response"))
                }
            }
        }
    }
    
    @MainActor
    private func createStreamingMessage(with text: String) {
        // Ensure we don't have an existing streaming message
        if streamingMessage != nil {
            return
        }
        
        let message = Message(content: "", isUser: false)
        message.conversation = conversation
        self.streamingMessage = message
        self.streamingText = ""
        
        Task {
            await streamTokens(text)
        }
    }
    
    private func streamTokens(_ fullText: String) async {
        // Stream character by character to preserve Markdown
        for (_, char) in fullText.enumerated() {
            // Check if streaming was cancelled
            guard streamingMessage != nil else { return }
            
            // Check connectivity
            guard networkMonitor.isConnected else {
                await MainActor.run {
                    completeStreamingWithError(.networkUnavailable)
                }
                return
            }
            
            try? await Task.sleep(nanoseconds: 30_000_000) // Faster for smoother appearance
            
            await MainActor.run {
                updateStreamingText(String(char))
            }
        }
        
        await MainActor.run {
            completeStreaming()
        }
    }
    
    @MainActor
    private func updateStreamingText(_ char: String) {
        guard let message = streamingMessage else { return }
        
        // Simply append the character without adding spaces
        streamingText += char
        message.content = streamingText
    }
    
    @MainActor
    private func completeStreaming() {
        guard let message = streamingMessage else { return }
        
        messageManager.completeStreamingMessage(message, in: conversation)
        
        // Clear streaming state
        streamingMessage = nil
        streamingText = ""
    }
    
    @MainActor
    private func completeStreamingWithError(_ error: AppError) {
        streamingMessage = nil
        streamingText = ""
        errorHandler(error)
    }
    
    @MainActor
    func deleteMessage(_ message: Message) {
        messageManager.deleteMessage(message, from: conversation)
    }
}
