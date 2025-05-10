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
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isThinking {
                            ThinkingBubble()
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation.messages.count) { oldValue, newValue in
                    // Scroll to bottom when new message arrives
                    if let lastMessage = conversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Growing text editor
                MessageInputView(text: $messageText)
                
                // Voice chat button
                Button(action: {
                    // TODO: Implement voice chat
                }) {
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
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Add user message
        let userMessage = Message(content: messageText, isUser: true)
        conversation.messages.append(userMessage)
        
        // Clear input
        let questionText = messageText
        messageText = ""
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Show thinking animation
        isThinking = true
        
        // Simulate API response
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            let aiResponse = Message(
                content: "This is a simulated response to: \(questionText)",
                isUser: false
            )
            
            conversation.messages.append(aiResponse)
            conversation.lastUpdated = Date()
            
            isThinking = false
            
            // Haptic feedback for response
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
