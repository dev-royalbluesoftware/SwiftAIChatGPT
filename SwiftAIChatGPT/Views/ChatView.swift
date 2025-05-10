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

// Views/ChatView.swift
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ChatViewModel
    
    init(conversation: Conversation) {
        self._viewModel = State(initialValue: ChatViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                
                Button(action: openVoiceChat) {
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
                        .foregroundColor(viewModel.messageText.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.messageText.isEmpty || viewModel.isThinking)
            }
            .padding()
        }
        .navigationTitle(viewModel.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Inject the modelContext from the environment into the viewModel
            viewModel.modelContext = modelContext
        }
    }
    
    private func openVoiceChat() {
        // TODO: Implement voice chat UI
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
