//
//
// SwiftAIChatGPT
// NavigationCoordinator.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI
import SwiftData

@Observable
final class NavigationCoordinator {
    var selectedConversation: Conversation?
    var showingConversationList = false
    
    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
        showingConversationList = false
    }
    
    func createNewConversation(in modelContext: ModelContext) -> Conversation? {
        do {
            let conversation = Conversation()
            modelContext.insert(conversation)
            try modelContext.save()
            selectConversation(conversation)
            return conversation
        } catch {
            print("Failed to create conversation: \(error)")
            return nil
        }
    }
    
    func deleteConversation(_ conversation: Conversation, from modelContext: ModelContext) {
        // If deleting the selected conversation, clear the selection
        if conversation.id == selectedConversation?.id {
            selectedConversation = nil
        }
        
        modelContext.delete(conversation)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }
}
