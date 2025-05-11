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
        .id(conversation.id)
        .onChange(of: conversation.id) { _, _ in
            resetForNewConversation()
        }
    }
    
    private func initializeViewModel() {
        let vm = ChatViewModel(conversation: conversation, modelContext: modelContext)
        viewModel = vm
        messageText = ""
    }
    
    private func resetForNewConversation() {
        messageText = ""
        showError = false
        errorMessage = nil
        actionHandler.stopSpeaking()
        viewModel = nil
        
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
            if newValue {
                showError = true
                errorMessage = viewModel.errorMessage
                viewModel.showError = false
            }
        }
        // Sync message text with view model
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)) { _ in
            // Ensure sync when keyboard appears
            if viewModel.messageText != messageText {
                viewModel.messageText = messageText
            }
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
                // Render conversation messages
                ForEach(conversation.messages) { message in
                    MessageBubble(message: message, actionHandler: actionHandler)
                        .id(message.id)
                        .transition(.asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                // Show thinking bubble
                if viewModel.isThinking {
                    ThinkingBubble()
                        .id("thinking")
                        .transition(.asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                // Show streaming message only if it exists and isn't already in messages
                if let streamingMessage = viewModel.streamingMessage,
                   !conversation.messages.contains(where: { $0.id == streamingMessage.id }) {
                    MessageBubble(message: streamingMessage, actionHandler: actionHandler)
                        .id("streaming-\(streamingMessage.id)")
                        .transition(.asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                // Bottom anchor for scrolling
                Color.clear
                    .frame(height: 1)
                    .id("bottom")
            }
            .padding()
            .animation(.easeInOut(duration: 0.3), value: conversation.messages.count)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isThinking)
            .animation(.easeInOut(duration: 0.3), value: viewModel.streamingMessage?.id)
        }
        .onChange(of: conversation.messages.count) { _, _ in
            scrollToBottom(proxy: proxy)
        }
        .onChange(of: viewModel.isThinking) { _, newValue in
            if newValue {
                scrollToBottom(proxy: proxy)
            }
        }
        .onChange(of: viewModel.streamingMessage?.content) { _, _ in
            scrollToBottom(proxy: proxy)
        }
        .onAppear {
            scrollToBottom(proxy: proxy)
        }
    }
    
    private func inputArea(viewModel: ChatViewModel) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            MessageInputView(text: $messageText)
                .onChange(of: messageText) { _, newValue in
                    viewModel.messageText = newValue
                }
            
            Button(action: {
                showingVoiceChat = true
            }) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            
            Button(action: {
                sendMessage(viewModel: viewModel)
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty || viewModel.isThinking)
        }
        .padding()
    }
    
    private func sendMessage(viewModel: ChatViewModel) {
        // Clear local text immediately for better UX
        messageText = ""
        
        Task {
            await viewModel.sendMessage()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
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
    }
}
