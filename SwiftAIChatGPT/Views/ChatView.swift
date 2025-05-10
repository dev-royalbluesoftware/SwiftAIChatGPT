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
    @Bindable var conversation: Conversation
    
    private let mockResponses = [
        "I understand your question. Let me help you with that.",
        "That's an interesting point! Here's what I think about it.",
        "Based on what you're asking, I would suggest considering these options.",
        "I see what you mean. Let me provide some insights on this topic."
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
                        }
                        
                        if isThinking {
                            ThinkingBubble()
                                .id("thinking")
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
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Simple text input
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
        
        // Simulate AI response
        Task {
            // Wait 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Stop thinking, add response
            isThinking = false
            
            // Haptic feedback for response
            impact.impactOccurred()
            
            // Add mock AI response
            let response = mockResponses.randomElement() ?? "I'm here to help!"
            let aiMessage = Message(content: response, isUser: false)
            conversation.messages.append(aiMessage)
            conversation.lastUpdated = Date()
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
