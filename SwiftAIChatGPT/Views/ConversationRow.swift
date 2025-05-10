//
// 
// SwiftAIChatGPT
// ConversationRow.swift
//
// Created by rbs-dev
// Copyright Royal Blue Software
//

import SwiftUI
import SwiftData

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
            
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Text(conversation.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Conversation.self, Message.self, configurations: config)
    let context = container.mainContext
    
    // Create a sample conversation
    let conversation = Conversation(title: "SwiftUI Discussion")
    
    // Add a sample message
    let message = Message(
        content: "SwiftUI is a great framework for building user interfaces. It provides a declarative way to define UI components.",
        isUser: true,
        timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
    )
    message.conversation = conversation
    conversation.messages.append(message)
    
    // Update the conversation's last update time
    conversation.lastUpdated = message.timestamp
    
    // Insert into context
    context.insert(conversation)
    
    return ConversationRow(conversation: conversation)
        .frame(maxWidth: 350)
        .modelContainer(container)
        .padding()
}
