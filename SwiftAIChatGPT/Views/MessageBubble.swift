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
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isUser ? Color.blue : Color(.systemGray5))
                    )
                    .foregroundColor(message.isUser ? .white : .primary)
                
                if !message.isUser {
                    // Action buttons for AI responses
                    HStack(spacing: 12) {
                        Button(action: copyMessage) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        
                        Button(action: playMessage) {
                            Label("Play", systemImage: "play.fill")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
    }
    
    private func copyMessage() {
        UIPasteboard.general.string = message.content
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func playMessage() {
        // TODO: Implement text-to-speech
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
