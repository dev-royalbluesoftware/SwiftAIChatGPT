//
//
// SwiftAIChatGPT
// ContentView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]
    
    var body: some View {
        MainChatView()
            .onAppear {
                // Create initial conversation if none exist
                if conversations.isEmpty {
                    let conversation = Conversation(title: "Welcome Chat")
                    modelContext.insert(conversation)
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
