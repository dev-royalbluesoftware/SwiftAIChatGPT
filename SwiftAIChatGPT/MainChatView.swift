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
                .alert("Error", isPresented: $coordinator.showError) {
                    Button("OK") {
                        coordinator.clearError()
                    }
                } message: {
                    Text(coordinator.errorMessage ?? "An error occurred")
                }
        }
        .onAppear {
            coordinator.setupInitialConversation(
                conversations: conversations,
                in: modelContext
            )
        }
        .onChange(of: conversations) { _, newConversations in
            handleConversationsChange(newConversations)
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
    
    private func handleConversationsChange(_ newConversations: [Conversation]) {
        if let selected = coordinator.selectedConversation,
           !newConversations.contains(where: { $0.id == selected.id }) {
            coordinator.selectedConversation = nil
        }
    }
}

// MARK: - WelcomeScreen
struct WelcomeScreen: View {
    @Environment(\.appCoordinator) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            welcomeHeader
            
            actionButtons
            
            Spacer()
        }
        .padding()
    }
    
    private var welcomeHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Welcome to AI Chat")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a conversation to begin")
                .foregroundColor(.gray)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                _ = coordinator.createNewConversation(in: modelContext)
            }) {
                Label("New Conversation", systemImage: "plus.bubble")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if !conversations.isEmpty {
                Button(action: {
                    coordinator.showConversationList()
                }) {
                    Label("View Conversations", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: 300)
    }
}

#Preview {
    MainChatView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
        .withAppCoordinator(.makePreview())
}
