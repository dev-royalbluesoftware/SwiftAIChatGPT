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
    private let modelContext: ModelContext
    
    // Network and error handling
    let networkMonitor = NetworkMonitor()
    var showError = false
    var errorMessage: String?
    
    init(conversation: Conversation, modelContext: ModelContext) {
        self.conversation = conversation
        self.modelContext = modelContext
    }
    
    private let mockResponses = [
        "I understand your question. Let me help you with that.",
        "That's an interesting point! Here's what I think about it.",
        "Based on what you're asking, I would suggest considering these options.",
        "I see what you mean. Let me provide some insights on this topic.",
        "**Great question!** Here's what I can tell you about that:\n\n *First*, let's consider the main aspects...",
        "This is a **fascinating** topic. Let me break it down:\n\n 1. The primary consideration\n 2. Secondary factors\n 3. Additional insights",
        "# Understanding Your Query\n\n Here's a detailed explanation:\n\n## Key Points\n- First important aspect\n- Second consideration\n- Third element\n\n> Remember: This is just a simulation!",
        "Let me think about this...\n\n```swift\n// Example code snippet\nfunc demonstrateFeature() {\n    print(\"This is a code example\")\n}\n```\n\nThe above code shows a simple implementation."
    ]
    
    @MainActor
    func sendMessage() async {
        guard !messageText.isEmpty else { return }
        
        // Check network connectivity
        guard networkMonitor.isConnected else {
            errorMessage = "No internet connection. Please check your network settings."
            showError = true
            return
        }
        
        // Haptic feedback
        HapticService.tick()
        
        // Create and add user message
        let userMessageContent = messageText
        let userMessage = Message(content: userMessageContent, isUser: true)
        
        // Configure relationship properly
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        
        // Update conversation metadata
        if conversation.messages.count == 1 {
            conversation.title = String(userMessageContent.prefix(50))
        }
        conversation.lastUpdated = Date()
        
        // Save using the model context
        do {
            modelContext.insert(userMessage)
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save message: \(error.localizedDescription)"
            showError = true
            return
        }
        
        // Clear input and show thinking
        messageText = ""
        isThinking = true
        
        // Clear any existing streaming message
        streamingMessage = nil
        streamingText = ""
        
        // Simulate API call
        Task {
            await simulateAPIResponse()
        }
    }
    
    private func simulateAPIResponse() async {
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Check if still connected
            guard networkMonitor.isConnected else {
                await MainActor.run {
                    isThinking = false
                    errorMessage = "Connection lost. Please try again."
                    showError = true
                }
                return
            }
            
            // Process response on main actor
            await MainActor.run {
                isThinking = false
                HapticService.tick()
                
                let responseText = mockResponses.randomElement() ?? "I'm here to help!"
                createStreamingMessage(with: responseText)
            }
        } catch {
            await MainActor.run {
                isThinking = false
                if error is CancellationError {
                    errorMessage = "Request was cancelled."
                } else {
                    errorMessage = "An error occurred. Please try again."
                }
                showError = true
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
        let words = fullText.split(separator: " ")
        
        for (index, word) in words.enumerated() {
            // Check if streaming was cancelled
            guard streamingMessage != nil else { return }
            
            // Check connectivity
            guard networkMonitor.isConnected else {
                await MainActor.run {
                    completeStreamingWithError("Connection lost during response.")
                }
                return
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            await MainActor.run {
                updateStreamingText(index: index, word: word)
            }
        }
        
        await MainActor.run {
            completeStreaming()
        }
    }
    
    @MainActor
    private func updateStreamingText(index: Int, word: Substring) {
        guard let message = streamingMessage else { return }
        
        if index > 0 {
            streamingText += " "
        }
        streamingText += String(word)
        message.content = streamingText
    }
    
    @MainActor
    private func completeStreaming() {
        guard let message = streamingMessage else { return }
        
        // Add to conversation only if not already there
        if !conversation.messages.contains(where: { $0.id == message.id }) {
            conversation.messages.append(message)
        }
        
        conversation.lastUpdated = Date()
        
        // Clear streaming state first
        let messageToSave = message  // Keep a reference for saving
        streamingMessage = nil
        streamingText = ""
        
        do {
            // Insert and save the completed message
            modelContext.insert(messageToSave)
            try modelContext.save()
        } catch {
            print("Failed to save conversation: \(error)")
            errorMessage = "Failed to save conversation."
            showError = true
        }
    }
    
    @MainActor
    private func completeStreamingWithError(_ error: String) {
        streamingMessage = nil
        streamingText = ""
        errorMessage = error
        showError = true
    }
    
    @MainActor
    func deleteMessage(_ message: Message) {
        modelContext.delete(message)
        conversation.lastUpdated = Date()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete message: \(error.localizedDescription)"
            showError = true
        }
    }
    
    deinit {
        streamingMessage = nil
        streamingText = ""
    }
}
