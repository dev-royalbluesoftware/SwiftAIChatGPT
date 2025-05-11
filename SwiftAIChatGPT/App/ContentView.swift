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
    var body: some View {
        MainChatView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
        .withAppCoordinator(.makePreview())
}
