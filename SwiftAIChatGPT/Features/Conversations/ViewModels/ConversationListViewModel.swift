//
//
// SwiftAIChatGPT
// ConversationListViewModel.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI
import SwiftData

@Observable
class ConversationListViewModel {
    private let modelContext: ModelContext
    var errorMessage: String?
    var showError = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createNewConversation() -> Conversation? {
        do {
            let newConversation = Conversation()
            modelContext.insert(newConversation)
            
            // Critical: Save to persist the new conversation
            try modelContext.save()
            return newConversation
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            showError = true
            print("Error creating conversation: \(error)")
            return nil
        }
    }
    
    func deleteConversations(conversations: [Conversation], at offsets: IndexSet) {
        do {
            for index in offsets {
                let conversation = conversations[index]
                
                // Cascade delete will handle messages (due to relationship configuration)
                modelContext.delete(conversation)
            }
            
            // Critical: Save to persist the deletion
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
            showError = true
            print("Error deleting conversations: \(error)")
        }
    }
    
    func updateConversationTitle(_ conversation: Conversation, title: String) {
        do {
            conversation.title = title
            conversation.lastUpdated = Date()
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update conversation: \(error.localizedDescription)"
            showError = true
            print("Error updating conversation: \(error)")
        }
    }
}
