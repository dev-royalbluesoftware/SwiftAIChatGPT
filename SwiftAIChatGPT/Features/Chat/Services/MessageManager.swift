//
//
// SwiftAIChatGPT
// MessageManager.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import SwiftData

@Observable
class MessageManager {
    private let modelContext: ModelContext
    private let errorHandler: (AppError) -> Void
    
    init(modelContext: ModelContext, errorHandler: @escaping (AppError) -> Void) {
        self.modelContext = modelContext
        self.errorHandler = errorHandler
    }
    
    func addMessage(_ message: Message, to conversation: Conversation) {
        message.conversation = conversation
        conversation.messages.append(message)
        conversation.lastUpdated = Date()
        
        do {
            modelContext.insert(message)
            try modelContext.save()
        } catch {
            errorHandler(.saveFailed("Could not save message"))
        }
    }
    
    func updateConversationTitle(_ conversation: Conversation, with text: String) {
        guard !text.isEmpty else { return }
        
        // Update title if this is the first message
        if conversation.messages.count == 1 {
            conversation.title = String(text.prefix(50))
        }
        
        conversation.lastUpdated = Date()
        
        do {
            try modelContext.save()
        } catch {
            errorHandler(.saveFailed("Could not update conversation"))
        }
    }
    
    func deleteMessage(_ message: Message, from conversation: Conversation) {
        modelContext.delete(message)
        conversation.lastUpdated = Date()
        
        do {
            try modelContext.save()
        } catch {
            errorHandler(.saveFailed("Could not delete message"))
        }
    }
    
    func completeStreamingMessage(_ message: Message, in conversation: Conversation) {
        // Add to conversation only if not already there
        if !conversation.messages.contains(where: { $0.id == message.id }) {
            conversation.messages.append(message)
        }
        
        conversation.lastUpdated = Date()
        
        do {
            // Insert and save the completed message
            modelContext.insert(message)
            try modelContext.save()
        } catch {
            errorHandler(.saveFailed("Could not save AI response"))
        }
    }
}
