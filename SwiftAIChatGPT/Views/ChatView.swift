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
    @State private var messageText = ""
    @State private var isThinking = false
    @State private var streamingMessage: Message?
    @State private var streamingText = ""
    @Bindable var conversation: Conversation
    
    private let mockResponses = [
        "I understand your question. Let me help you with that.",
        "That's an interesting point! Here's what I think about it.",
        "Based on what you're asking, I would suggest considering these options.",
        "I see what you mean. Let me provide some insights on this topic.",
        "**Great question!** Here's what I can tell you about that:\n\n*First*, let's consider the main aspects...",
        "This is a **fascinating** topic. Let me break it down:\n\n1. The primary consideration\n2. Secondary factors\n3. Additional insights"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list with manual scroll-to-bottom
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .slide),
                                    removal: .opacity
                                ))
                        }
                        
                        if isThinking {
                            ThinkingBubble()
                                .id("thinking")
                                .transition(.opacity)
                        }
                        
                        // Show streaming message if available
                        if let streamingMessage = streamingMessage {
                            MessageBubble(message: streamingMessage)
                                .id("streaming")
                                .transition(.opacity)
                        }
                        
                        // Invisible anchor for bottom scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: conversation.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isThinking) { _, newValue in
                    if newValue {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: streamingMessage) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Message input
                MessageInputView(text: $messageText)
                
                // Voice button (UI only for now)
                Button(action: openVoiceChat) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .frame(width: 44, height: 44)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty || isThinking)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            // Dismiss keyboard
            hideKeyboard()
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Add user message
        let userMessage = Message(content: messageText, isUser: true)
        conversation.messages.append(userMessage)
        
        // Clear input and show thinking
        messageText = ""
        isThinking = true
        
        // Dismiss keyboard
        hideKeyboard()
        
        // Simulate AI response with streaming
        Task {
            // Wait 2 seconds for thinking
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Stop thinking, prepare for streaming
            await MainActor.run {
                isThinking = false
                
                // Haptic feedback for first token
                impact.impactOccurred()
                
                // Start streaming
                let responseText = mockResponses.randomElement() ?? "I'm here to help!"
                streamingMessage = Message(content: "", isUser: false)
                streamTokens(responseText)
            }
        }
    }
    
    private func streamTokens(_ fullText: String) {
        let words = fullText.split(separator: " ")
        streamingText = ""
        
        Task {
            for (index, word) in words.enumerated() {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second per word
                
                await MainActor.run {
                    if index > 0 {
                        streamingText += " "
                    }
                    streamingText += String(word)
                    
                    // Update streaming message
                    if streamingMessage != nil {
                        streamingMessage!.content = streamingText
                    }
                }
            }
            
            // After streaming is complete, add the message to conversation
            await MainActor.run {
                if let message = streamingMessage {
                    conversation.messages.append(message)
                    conversation.lastUpdated = Date()
                    streamingMessage = nil
                }
            }
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
