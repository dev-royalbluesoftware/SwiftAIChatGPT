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
    @Query(sort: \Conversation.lastUpdated, order: .reverse)
    private var conversations: [Conversation]
    @State private var coordinator = NavigationCoordinator()
    
    var body: some View {
        NavigationStack {
            mainContent
                .sheet(isPresented: $coordinator.showingConversationList) {
                    conversationListSheet
                }
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: conversations) { _, newConversations in
            handleConversationsChange(newConversations)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let selectedConversation = coordinator.selectedConversation {
            ChatViewContainer(
                conversation: selectedConversation,
                coordinator: coordinator
            )
        } else {
            WelcomeScreen(
                coordinator: coordinator,
                hasConversations: !conversations.isEmpty,
                onCreateConversation: createNewConversation
            )
        }
    }
    
    private var conversationListSheet: some View {
        NavigationStack {
            ConversationListView(coordinator: coordinator)
        }
    }
    
    private func setupInitialState() {
        if conversations.isEmpty {
            createInitialConversation()
        } else if coordinator.selectedConversation == nil {
            coordinator.selectedConversation = conversations.first
        }
    }
    
    private func handleConversationsChange(_ newConversations: [Conversation]) {
        if let selected = coordinator.selectedConversation,
           !newConversations.contains(where: { $0.id == selected.id }) {
            coordinator.selectedConversation = nil
        }
    }
    
    private func createNewConversation() {
        _ = coordinator.createNewConversation(in: modelContext)
    }
    
    private func createInitialConversation() {
        let conversation = Conversation(title: "Welcome Chat")
        modelContext.insert(conversation)
        do {
            try modelContext.save()
            coordinator.selectedConversation = conversation
        } catch {
            print("Failed to create initial conversation: \(error)")
        }
    }
}

// MARK: - ChatViewContainer
struct ChatViewContainer: View {
    let conversation: Conversation
    @Bindable var coordinator: NavigationCoordinator
    
    var body: some View {
        ChatView(conversation: conversation)
            .id(conversation.id)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        coordinator.showingConversationList = true
                    }) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
    }
}

// MARK: - WelcomeScreen
struct WelcomeScreen: View {
    @Bindable var coordinator: NavigationCoordinator
    let hasConversations: Bool
    let onCreateConversation: () -> Void
    
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
            Button(action: onCreateConversation) {
                Label("New Conversation", systemImage: "plus.bubble")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if hasConversations {
                Button(action: {
                    coordinator.showingConversationList = true
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
}
