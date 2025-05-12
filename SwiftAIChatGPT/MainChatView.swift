//
//
// SwiftAIChatGPT
// MainChatView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import SwiftData

struct MainChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appCoordinator) private var coordinator
    @Query(sort: \Conversation.lastUpdated, order: .reverse)
    private var conversations: [Conversation]
    
    var body: some View {
        @Bindable var coordinator = coordinator
        
        NavigationStack {
            mainContent
                .sheet(isPresented: $coordinator.showingConversationList) {
                    conversationListSheet
                }
                .errorHandler(coordinator.errorState) {
                    // Retry action based on the error
                    coordinator.handleRetry(modelContext: modelContext)
                } onSettings: {
                    // Open settings
                    coordinator.openSettings()
                }
        }
        .onAppear {
            coordinator.setupInitialConversation(
                conversations: conversations,
                in: modelContext
            )
        }
        .onChange(of: conversations) { _, newConversations in
            coordinator.handleConversationsChange(newConversations)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let selectedConversation = coordinator.selectedConversation {
            ChatView(conversation: selectedConversation)
                .id(selectedConversation.id)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            coordinator.showConversationList()
                        }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
        } else {
            WelcomeScreen()
        }
    }
    
    private var conversationListSheet: some View {
        NavigationStack {
            ConversationListView()
        }
    }
}

#Preview {
    MainChatView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
        .withAppCoordinator(.makePreview())
}
