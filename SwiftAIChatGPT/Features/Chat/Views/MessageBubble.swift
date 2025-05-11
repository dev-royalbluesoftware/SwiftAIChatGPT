//
//
// SwiftAIChatGPT
// MessageBubble.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import SwiftUI
import SwiftData

struct MessageBubble: View {
    let message: Message
    let actionHandler: MessageActionHandler
    @State private var appeared = false
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Render markdown for AI messages, plain text for user
                if message.isUser {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                } else {
                    // AI message with enhanced markdown support and fade-in animation
                    MarkdownView(text: message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray5))
                        )
                        .foregroundColor(.primary)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3), value: appeared)
                }
                
                if !message.isUser {
                    // Action buttons for AI messages
                    HStack(spacing: 12) {
                        Button(action: {
                            actionHandler.copyMessage(message)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: actionHandler.copiedMessageId == message.id ? "checkmark" : "doc.on.doc")
                                Text(actionHandler.copiedMessageId == message.id ? "Copied" : "Copy")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            actionHandler.toggleSpeech(for: message)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: actionHandler.isSpeaking ? "stop.fill" : "play.fill")
                                Text(actionHandler.isSpeaking ? "Stop" : "Play")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .foregroundColor(.gray)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.2), value: appeared)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
        .onAppear {
            if !message.isUser {
                // Fade in animation for AI messages
                withAnimation {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
    }
}

#Preview {
    let actionHandler = MessageActionHandler()
    
    return VStack(spacing: 20) {
        MessageBubble(
            message: Message(content: "Hello, how can I help you today?", isUser: false),
            actionHandler: actionHandler
        )
        MessageBubble(
            message: Message(content: "I need help with SwiftUI", isUser: true),
            actionHandler: actionHandler
        )
        MessageBubble(
            message: Message(content: "**SwiftUI** is a powerful framework for building *user interfaces*. Here's what you need to know:\n\n1. Declarative syntax\n2. Live previews\n3. Cross-platform support", isUser: false),
            actionHandler: actionHandler
        )
    }
    .padding()
}
