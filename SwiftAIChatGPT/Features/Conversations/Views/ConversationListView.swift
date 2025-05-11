//
//
// SwiftAIChatGPT
// ConversationListView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Conversation.lastUpdated, order: .reverse)
    private var conversations: [Conversation]
    
    @Bindable var coordinator: NavigationCoordinator
    
    var body: some View {
        List {
            ForEach(conversations) { conversation in
                ConversationRowButton(
                    conversation: conversation,
                    isSelected: conversation.id == coordinator.selectedConversation?.id,
                    action: {
                        selectConversation(conversation)
                    }
                )
            }
            .onDelete(perform: deleteConversations)
        }
        .navigationTitle("Conversations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .overlay {
            if conversations.isEmpty {
                emptyStateView
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: createNewConversation) {
                Image(systemName: "square.and.pencil")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
                dismiss()
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Conversations",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Tap the pencil icon to start a new conversation")
        )
    }
    
    private func selectConversation(_ conversation: Conversation) {
        coordinator.selectConversation(conversation)
        dismiss()
    }
    
    private func createNewConversation() {
        _ = coordinator.createNewConversation(in: modelContext)
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversations[index]
            coordinator.deleteConversation(conversation, from: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        ConversationListView(coordinator: NavigationCoordinator())
            .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    }
}
