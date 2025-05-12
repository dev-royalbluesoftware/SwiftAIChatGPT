//
//
// SwiftAIChatGPT
// WelcomeScreen.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import SwiftData

struct WelcomeScreen: View {
    @Environment(\.appCoordinator) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            welcomeHeader
            
            actionButtons
            
            Spacer()
        }
        .padding()
    }
    
    private var welcomeHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Welcome to AI Chat")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a conversation to begin")
                .foregroundColor(.gray)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                _ = coordinator.createNewConversation(in: modelContext)
            }) {
                Label("New Conversation", systemImage: "plus.bubble")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if !conversations.isEmpty {
                Button(action: {
                    coordinator.showConversationList()
                }) {
                    Label("View Conversations", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: 300)
    }
}
