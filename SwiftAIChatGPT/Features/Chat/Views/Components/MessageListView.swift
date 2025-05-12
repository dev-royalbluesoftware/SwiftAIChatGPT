//
//
// SwiftAIChatGPT
// MessageListView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import SwiftData

struct MessageListView: View {
    let conversation: Conversation
    let viewModel: ChatViewModel
    let actionHandler: MessageActionHandler
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
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
                    
                    // Show streaming message
                    if let streamingMessage = viewModel.streamingMessage,
                       !conversation.messages.contains(where: { $0.id == streamingMessage.id }) {
                        MessageBubble(message: streamingMessage, actionHandler: actionHandler)
                            .id("streaming-\(streamingMessage.id)")
                            .transition(.asymmetric(
                                insertion: .slide.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    // Bottom anchor
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
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}
