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
    @State private var viewModel: ChatViewModel?
    @State private var actionHandler = MessageActionHandler()
    @State private var showingVoiceChat = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var messageText = ""
    
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
        .id(conversation.id) // Force view refresh when conversation changes
        .onChange(of: conversation.id) { _, _ in
            // Reset view model when conversation changes
            resetForNewConversation()
        }
    }
    
    private func initializeViewModel() {
        let vm = ChatViewModel(conversation: conversation, modelContext: modelContext)
        viewModel = vm
        messageText = ""
    }
    
    private func resetForNewConversation() {
        // Reset all state for new conversation
        messageText = ""
        showError = false
        errorMessage = nil
        actionHandler.stopSpeaking()
        viewModel = nil
        
        // Reinitialize with new conversation
        DispatchQueue.main.async {
            initializeViewModel()
        }
    }
    
    @ViewBuilder
    private func chatContent(viewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            // Network status banner
            if !viewModel.networkMonitor.isConnected {
                networkStatusBanner()
            }
            
            // Messages list
            ScrollViewReader { proxy in
                messageScrollView(viewModel: viewModel, proxy: proxy)
            }
            
            // Input area
            inputArea(viewModel: viewModel)
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $showingVoiceChat) {
            VoiceChatView()
        }
        .toast(isShowing: $showError, message: errorMessage ?? "", type: .error)
        .onChange(of: viewModel.showError) { _, newValue in
            showError = newValue
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            errorMessage = newValue
        }
        .onChange(of: viewModel.messageText) { _, newValue in
            messageText = newValue
        }
        .onChange(of: messageText) { _, newValue in
            viewModel.messageText = newValue
        }
    }
    
    private func networkStatusBanner() -> some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("No Internet Connection")
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
    }
    
    private func messageScrollView(viewModel: ChatViewModel, proxy: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.conversation.messages) { message in
                    MessageBubble(message: message, actionHandler: actionHandler)
                        .id(message.id)
                }
                
                if viewModel.isThinking {
                    ThinkingBubble()
                        .id("thinking")
                }
                
                if let streamingMessage = viewModel.streamingMessage {
                    MessageBubble(message: streamingMessage, actionHandler: actionHandler)
                        .id("streaming")
                }
                
                Color.clear
                    .frame(height: 1)
                    .id("bottom")
            }
            .padding()
        }
        .onChange(of: viewModel.conversation.messages.count) { _, _ in
            scrollToBottom(proxy: proxy)
        }
        .onChange(of: viewModel.isThinking) { _, newValue in
            if newValue {
                scrollToBottom(proxy: proxy)
            }
        }
        .onChange(of: viewModel.streamingMessage) { _, _ in
            scrollToBottom(proxy: proxy)
        }
        .onAppear {
            scrollToBottom(proxy: proxy)
        }
    }
    
    private func inputArea(viewModel: ChatViewModel) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            MessageInputView(text: $messageText)
            
            Button(action: {
                showingVoiceChat = true
            }) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            
            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty || viewModel.isThinking)
        }
        .padding()
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ChatView(conversation: Conversation())
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
