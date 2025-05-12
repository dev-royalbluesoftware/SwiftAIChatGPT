//
//
// SwiftAIChatGPTTests
// ConversationModelTests.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import XCTest
import SwiftData
@testable import SwiftAIChatGPT

@MainActor
final class ConversationModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    @MainActor
    override func setUp() {
        super.setUp()
        // Create in-memory container for testing
        let schema = Schema([Conversation.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            container = try ModelContainer(for: schema, configurations: config)
            context = container.mainContext
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    @MainActor
    override func tearDown() {
        // Make sure we don't have dangling references
        container = nil
        context = nil
        super.tearDown()
    }
    
    @MainActor
    func testCreateConversation() {
        // Given
        let title = "Test Conversation"
        let date = Date()
        
        // When
        let conversation = Conversation(title: title, createdAt: date)
        context.insert(conversation)
        
        // Then
        XCTAssertEqual(conversation.title, title)
        XCTAssertEqual(conversation.createdAt, date)
        XCTAssertEqual(conversation.lastUpdated, date)
        XCTAssertEqual(conversation.messages.count, 0)
    }
    
    @MainActor
    func testAddMessageToConversation() {
        // Given
        let conversation = Conversation()
        context.insert(conversation)
        
        // When
        let message = Message(content: "Hello", isUser: true)
        message.conversation = conversation
        conversation.messages.append(message)
        
        // Then
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.first?.content, "Hello")
        XCTAssertEqual(conversation.messages.first?.isUser, true)
    }
    
    @MainActor
    func testCascadeDeletion() throws {
        // Given - Create new conversation and insert it
        let conversation = Conversation()
        context.insert(conversation)
        
        // Create a message and add it to the conversation
        let message = Message(content: "Test Message", isUser: true)
        message.conversation = conversation
        conversation.messages.append(message)
        context.insert(message)
        
        // Save context
        try context.save()
        
        // Capture IDs for later comparison
        let conversationId = conversation.id
        let messageId = message.id
        
        // When - Delete the conversation
        context.delete(conversation)
        try context.save()
        
        // Then - Check that conversation is gone
        let allConversations = try context.fetch(FetchDescriptor<Conversation>())
        let foundConversations = allConversations.filter { $0.id == conversationId }
        XCTAssertEqual(foundConversations.count, 0, "Conversation should be deleted")
        
        // Check message was also deleted through cascade rule
        let allMessages = try context.fetch(FetchDescriptor<Message>())
        let foundMessages = allMessages.filter { $0.id == messageId }
        XCTAssertEqual(foundMessages.count, 0, "Message should be deleted via cascade rule")
    }
}
