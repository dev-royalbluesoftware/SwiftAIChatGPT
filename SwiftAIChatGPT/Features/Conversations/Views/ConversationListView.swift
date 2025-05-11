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
    @Query(sort: \Conversation.lastUpdated, order: .reverse)
    private var conversations: [Conversation]
    @State private var showingNewConversation = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(conversations) { conversation in
                    NavigationLink(destination: ChatView(conversation: conversation)) {
                        ConversationRow(conversation: conversation)
                    }
                }
                .onDelete(perform: deleteConversations)
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
    }
    
    private func createNewConversation() {
        let newConversation = Conversation()
        modelContext.insert(newConversation)
        showingNewConversation = true
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])
        }
    }
}

#Preview {
    ConversationListView()
}
