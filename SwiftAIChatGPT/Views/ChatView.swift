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
    @State private var networkMonitor = NetworkMonitor()
    @State private var viewModel: ChatViewModel
    @State private var showingVoiceChat = false
    @State private var showingConversationList = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(conversation: Conversation) {
        self._viewModel = State(initialValue: ChatViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Network status banner
            if !networkMonitor.isConnected {
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
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isThinking {
                            ThinkingBubble()
                                .id("thinking")
                        }
                        
                        if let streamingMessage = viewModel.streamingMessage {
                            MessageBubble(message: streamingMessage)
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
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                MessageInputView(text: $viewModel.messageText)
                
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
                        do {
                            if networkMonitor.isConnected {
                                await viewModel.sendMessage()
                            } else {
                                throw ChatError.networkUnavailable
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.messageText.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.messageText.isEmpty || viewModel.isThinking)
            }
            .padding()
        }
        .navigationTitle(viewModel.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingConversationList = true
                }) {
                    Image(systemName: "list.bullet")
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
        .sheet(isPresented: $showingVoiceChat) {
            VoiceChatView()
        }
        .sheet(isPresented: $showingConversationList) {
            NavigationStack {
                ConversationSelectionView(selectedConversation: .constant(viewModel.conversation))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingConversationList = false
                            }
                        }
                    }
            }
        }
        .toast(isShowing: $showError, message: errorMessage, type: .error)
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
