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
    @State private var viewModel: ChatViewModel?
    @State private var actionHandler = MessageActionHandler()
    
    let conversation: Conversation
    
    init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                chatContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        initializeViewModel()
                    }
            }
        }
        .id(conversation.id)
        .onChange(of: conversation.id) { _, _ in
            resetForNewConversation()
        }
    }
    
    private func initializeViewModel() {
        let vm = ChatViewModel(
            conversation: conversation,
            modelContext: modelContext,
            networkMonitor: coordinator.networkMonitor,
            errorHandler: { error in
                coordinator.handleError(error)
            }
        )
        viewModel = vm
    }
    
    private func resetForNewConversation() {
        actionHandler.stopSpeaking()
        viewModel = nil
        
        DispatchQueue.main.async {
            initializeViewModel()
        }
    }
    
    @ViewBuilder
    private func chatContent(viewModel: ChatViewModel) -> some View {
        @Bindable var coordinator = coordinator
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
                actionHandler: actionHandler
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
        .sheet(isPresented: $coordinator.showingVoiceChat) {
            VoiceChatView()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: Conversation())
            .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
            .withAppCoordinator(.makePreview())
    }
}
