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
    
    @State private var viewModel: ConversationListViewModel?
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(conversations) { conversation in
                    Button(action: {
                        selectConversation(conversation)
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
        .onAppear {
            if viewModel == nil {
                viewModel = ConversationListViewModel(modelContext: modelContext)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onChange(of: viewModel?.showError) { _, newValue in
            if let vm = viewModel, vm.showError {
                errorMessage = vm.errorMessage
                showError = true
                vm.showError = false  // Reset the view model's state
            }
        }
    }
    
    private func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
        dismiss()
    }
    
    private func createNewConversation() {
        guard let viewModel = viewModel else { return }
        
        if let conversation = viewModel.createNewConversation() {
            selectedConversation = conversation
            dismiss()
        }
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        
        // Check if we're deleting the selected conversation
        for index in offsets {
            let conversation = conversations[index]
            if conversation == selectedConversation {
                selectedConversation = nil
            }
        }
        
        viewModel.deleteConversations(conversations: Array(conversations), at: offsets)
    }
}
