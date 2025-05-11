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
    var conversation: Conversation
    var modelContext: ModelContext?
    
    // Network monitoring
    let networkMonitor = NetworkMonitor()
    var errorMessage: String?
    
    init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    private let mockResponses = [
        "I understand your question. Let me help you with that.",
        "That's an interesting point! Here's what I think about it.",
        "Based on what you're asking, I would suggest considering these options.",
        "I see what you mean. Let me provide some insights on this topic.",
        "**Great question!** Here's what I can tell you about that:\n\n*First*, let's consider the main aspects...",
        "This is a **fascinating** topic. Let me break it down:\n\n1. The primary consideration\n2. Secondary factors\n3. Additional insights",
        "# Understanding Your Query\n\nHere's a detailed explanation:\n\n## Key Points\n- First important aspect\n- Second consideration\n- Third element\n\n> Remember: This is just a simulation!",
        "Let me think about this...\n\n```swift\n// Example code snippet\nfunc demonstrateFeature() {\n    print(\"This is a code example\")\n}\n```\n\nThe above code shows a simple implementation."
    ]
    
    func sendMessage() async {
        guard !messageText.isEmpty else { return }
        
        // Check network connectivity
        guard networkMonitor.isConnected else {
            await MainActor.run {
                errorMessage = "No internet connection. Please check your network settings."
            }
            return
        }
        
        // Haptic feedback
        await MainActor.run {
            HapticService.tick()
        }
        
        // Add user message
        let userMessage = Message(content: messageText, isUser: true)
        conversation.messages.append(userMessage)
        
        // Update conversation title if it's the first message
        if conversation.messages.count == 1 {
            conversation.title = String(messageText.prefix(50))
        }
        
        // Clear input and show thinking
        messageText = ""
        isThinking = true
        
        // Simulate API call delay
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Check if still connected after delay
            guard networkMonitor.isConnected else {
                await MainActor.run {
                    isThinking = false
                    errorMessage = "Connection lost. Please try again."
                }
                return
            }
            
            await MainActor.run {
                isThinking = false
                HapticService.tick()
                
                let responseText = mockResponses.randomElement() ?? "I'm here to help!"
                streamingMessage = Message(content: "", isUser: false)
                
                Task {
                    await streamTokens(responseText)
                }
            }
        } catch {
            await MainActor.run {
                isThinking = false
                if error is CancellationError {
                    errorMessage = "Request was cancelled."
                } else {
                    errorMessage = "An error occurred. Please try again."
                }
            }
        }
    }
    
    private func streamTokens(_ fullText: String) async {
        let words = fullText.split(separator: " ")
        streamingText = ""
        
        for (index, word) in words.enumerated() {
            // Check if still connected during streaming
            guard networkMonitor.isConnected else {
                await MainActor.run {
                    streamingMessage = nil
                    errorMessage = "Connection lost during response."
                }
                return
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            await MainActor.run {
                if index > 0 {
                    streamingText += " "
                }
                streamingText += String(word)
                
                if streamingMessage != nil {
                    streamingMessage!.content = streamingText
                }
            }
        }
        
        await MainActor.run {
            if let message = streamingMessage {
                conversation.messages.append(message)
                conversation.lastUpdated = Date()
                
                // Save to persistent storage
                if let context = modelContext {
                    do {
                        try context.save()
                    } catch {
                        print("Failed to save conversation: \(error)")
                    }
                }
                
                streamingMessage = nil
            }
        }
    }
}
