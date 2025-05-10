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
    
    init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    // Mock responses remain the same
    private let mockResponses = [
        "I understand your question. Let me help you with that.",
        "That's an interesting point! Here's what I think about it.",
        "Based on what you're asking, I would suggest considering these options.",
        "I see what you mean. Let me provide some insights on this topic.",
        "**Great question!** Here's what I can tell you about that:\n\n*First*, let's consider the main aspects...",
        "This is a **fascinating** topic. Let me break it down:\n\n1. The primary consideration\n2. Secondary factors\n3. Additional insights"
    ]
    
    func sendMessage() async {
        guard !messageText.isEmpty else { return }
        
        // Haptic feedback
        await MainActor.run {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        
        // Add user message
        let userMessage = Message(content: messageText, isUser: true)
        conversation.messages.append(userMessage)
        
        // Clear input and show thinking
        messageText = ""
        isThinking = true
        
        // Simulate AI response
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            isThinking = false
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            let responseText = mockResponses.randomElement() ?? "I'm here to help!"
            streamingMessage = Message(content: "", isUser: false)
            Task {
                await streamTokens(responseText)
            }
        }
    }
    
    private func streamTokens(_ fullText: String) async {
        let words = fullText.split(separator: " ")
        streamingText = ""
        
        for (index, word) in words.enumerated() {
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
                streamingMessage = nil
            }
        }
    }
}
