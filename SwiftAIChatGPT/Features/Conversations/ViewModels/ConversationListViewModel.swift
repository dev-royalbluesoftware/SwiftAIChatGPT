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
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createNewConversation() -> Conversation {
        let newConversation = Conversation()
        modelContext.insert(newConversation)
        return newConversation
    }
    
    func deleteConversations(conversations: [Conversation], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])
        }
    }
}
