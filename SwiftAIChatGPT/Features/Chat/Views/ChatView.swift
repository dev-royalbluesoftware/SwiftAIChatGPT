//
//
// SwiftAIChatGPT
// ChatView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appCoordinator) private var coordinator
    @State private var chatCoordinator: ChatCoordinator?
    
    let conversation: Conversation
    
    init(conversation: Conversation) {
        self.conversation = conversation
        // Don't initialize chatCoordinator here since environment values aren't available yet
    }
    
    var body: some View {
        Group {
            if let chatCoordinator = chatCoordinator, let viewModel = chatCoordinator.viewModel {
                chatContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        initializeChatCoordinator()
                    }
            }
        }
        .id(conversation.id)
        .onChange(of: conversation.id) { _, _ in
            resetForNewConversation()
            DispatchQueue.main.async {
                initializeChatCoordinator()
            }
        }
    }
    
    private func initializeChatCoordinator() {
        // Create the coordinator now that environment values are available
        let newCoordinator = ChatCoordinator(
            modelContext: modelContext,
            appCoordinator: coordinator
        )
        
        // Initialize the view model
        newCoordinator.initializeViewModel(for: conversation)
        
        // Set the coordinator
        self.chatCoordinator = newCoordinator
    }
    
    private func resetForNewConversation() {
        chatCoordinator?.resetForNewConversation()
        chatCoordinator = nil
    }
    
    @ViewBuilder
    private func chatContent(viewModel: ChatViewModel) -> some View {
        @Bindable var appCoordinator = coordinator
        @Bindable var vm = viewModel
        
        VStack(spacing: 0) {
            // Network status banner
            if !coordinator.networkMonitor.isConnected {
                NetworkStatusBanner()
            }
            
            // Messages list
            MessageListView(
                conversation: conversation,
                viewModel: viewModel,
                actionHandler: chatCoordinator?.actionHandler ?? MessageActionHandler()
            )
            
            Divider()
            
            // Input area - fixed at bottom
            ChatInputArea(viewModel: vm)
                .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $appCoordinator.showingVoiceChat) {
            VoiceChatView()
        }
    }
    
    private func hideKeyboard() {
        chatCoordinator?.hideKeyboard()
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: Conversation())
            .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
            .withAppCoordinator(.makePreview())
    }
}
