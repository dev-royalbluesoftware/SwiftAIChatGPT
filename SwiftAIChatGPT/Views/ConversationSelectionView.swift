//
//
// SwiftAIChatGPT
// ConversationSelectionView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 

import SwiftUI
import SwiftData

struct ConversationSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Conversation.lastUpdated, order: .reverse)
    private var conversations: [Conversation]
    @Binding var selectedConversation: Conversation?
    
    var body: some View {
        List {
            ForEach(conversations) { conversation in
                Button(action: {
                    selectedConversation = conversation
                    dismiss()
                }) {
                    ConversationRow(conversation: conversation)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .onDelete(perform: deleteConversations)
        }
        .navigationTitle("Conversations")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: createNewConversation) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .overlay {
            if conversations.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Tap the pencil icon to start a new conversation")
                )
            }
        }
    }
    
    private func createNewConversation() {
        let conversation = Conversation()
        modelContext.insert(conversation)
        selectedConversation = conversation
        dismiss()
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversations[index]
            if conversation == selectedConversation {
                selectedConversation = nil
            }
            modelContext.delete(conversation)
        }
    }
}
