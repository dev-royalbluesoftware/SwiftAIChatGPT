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
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query private var conversations: [Conversation]
    @State private var selectedConversation: Conversation?
    @State private var showingConversationList = false
    
    var body: some View {
        Group {
            if let selectedConversation = selectedConversation {
                NavigationStack {
                    ChatView(conversation: selectedConversation)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    showingConversationList = true
                                }) {
                                    Image(systemName: "list.bullet")
                                }
                            }
                        }
                }
                .sheet(isPresented: $showingConversationList) {
                    NavigationStack {
                        ConversationSelectionView(selectedConversation: $selectedConversation)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showingConversationList = false
                                    }
                                }
                            }
                    }
                }
            } else {
                // Initial view when no conversation is selected
                NavigationStack {
                    VStack {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("Welcome to AI Chat")
                            .font(.title2)
                            .padding(.top)
                        Text("Start a conversation to begin")
                            .foregroundColor(.gray)
                        
                        Button(action: createNewConversation) {
                            Label("New Conversation", systemImage: "plus.bubble")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            if conversations.isEmpty {
                createInitialConversation()
            } else if selectedConversation == nil {
                selectedConversation = conversations.first
            }
        }
    }
    
    private func createNewConversation() {
        let conversation = Conversation()
        modelContext.insert(conversation)
        selectedConversation = conversation
    }
    
    private func createInitialConversation() {
        let conversation = Conversation(title: "Welcome Chat")
        modelContext.insert(conversation)
        selectedConversation = conversation
    }
}

struct ConversationSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Conversation.lastUpdated, order: .reverse)
    private var conversations: [Conversation]
    @Binding var selectedConversation: Conversation?
    
    var body: some View {
        List {
            ForEach(conversations) { conversation in
                Button(action: {
                    selectedConversation = conversation
                    dismiss()
                }) {
                    ConversationRow(conversation: conversation)
                }
                .foregroundColor(.primary)
            }
            .onDelete(perform: deleteConversations)
        }
        .navigationTitle("Conversations")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: createNewConversation) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
    
    private func createNewConversation() {
        let conversation = Conversation()
        modelContext.insert(conversation)
        selectedConversation = conversation
        dismiss()
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
