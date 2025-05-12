//
//
// SwiftAIChatGPTTests
// AppCoordinatorTests.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import XCTest
import SwiftData
@testable import SwiftAIChatGPT

@MainActor
final class AppCoordinatorTests: XCTestCase {
    var coordinator: AppCoordinator!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = AppCoordinator()
        
        // Set up in-memory SwiftData container
        let schema = Schema([Conversation.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContext = modelContainer.mainContext
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    @MainActor
    override func tearDown() {
        // To prevent crashes, we need to clear any dangling references
        // Set properties to nil to break reference cycles
        coordinator = nil
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    @MainActor
    func testCreateNewConversation() throws {
        // Given
        XCTAssertNil(coordinator.selectedConversation)
        
        // When
        let conversation = coordinator.createNewConversation(in: modelContext)
        
        // Then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(coordinator.selectedConversation?.id, conversation?.id)
        
        // Clean up to prevent context issues
        if let conversation = conversation {
            modelContext.delete(conversation)
            try modelContext.save()
        }
    }
    
    @MainActor
    func testDeleteConversation() throws {
        // Given
        let conversation = coordinator.createNewConversation(in: modelContext)!
        XCTAssertEqual(coordinator.selectedConversation?.id, conversation.id)
        
        // Save the ID for later comparison
        let conversationId = conversation.id
        
        // When
        coordinator.deleteConversation(conversation, from: modelContext)
        
        // Then
        XCTAssertNil(coordinator.selectedConversation)
        
        // Verify it's deleted from the context
        let allConversations = try modelContext.fetch(FetchDescriptor<Conversation>())
        let matchingConversations = allConversations.filter { $0.id == conversationId }
        XCTAssertEqual(matchingConversations.count, 0, "Conversation should be deleted")
    }
    
    @MainActor
    func testNavigationActions() {
        // Given - Create a new conversation that isn't in the context to avoid SwiftData issues
        let conversation = Conversation()
        
        // When & Then - Test select conversation
        coordinator.selectConversation(conversation)
        XCTAssertEqual(coordinator.selectedConversation?.id, conversation.id)
        XCTAssertFalse(coordinator.showingConversationList)
        
        // When & Then - Test show conversation list
        coordinator.showConversationList()
        XCTAssertTrue(coordinator.showingConversationList)
        
        // When & Then - Test show voice chat
        coordinator.showVoiceChat()
        XCTAssertTrue(coordinator.showingVoiceChat)
        
        // When & Then - Test dismiss voice chat
        coordinator.dismissVoiceChat()
        XCTAssertFalse(coordinator.showingVoiceChat)
        
        // Clean up to prevent issues in other tests
        coordinator.selectedConversation = nil
    }
    
    @MainActor
    func testErrorHandling() {
        // Given
        XCTAssertFalse(coordinator.errorState.isShowing)
        
        // When
        coordinator.handleError(.networkUnavailable)
        
        // Then
        XCTAssertTrue(coordinator.errorState.isShowing)
        XCTAssertEqual(coordinator.errorState.currentError, .networkUnavailable)
        
        // When
        coordinator.clearError()
        
        // Then
        XCTAssertFalse(coordinator.errorState.isShowing)
        XCTAssertNil(coordinator.errorState.currentError)
    }
    
    @MainActor
    func testSetupInitialConversation() throws {
        // Given
        var conversations = [Conversation]()
        
        // When - Empty conversations array
        coordinator.setupInitialConversation(conversations: conversations, in: modelContext)
        
        // Then
        XCTAssertNotNil(coordinator.selectedConversation)
        XCTAssertEqual(coordinator.selectedConversation?.title, "Welcome Chat")
        
        // Clean up first setup to avoid holding references
        let selectedId = coordinator.selectedConversation?.id
        coordinator.selectedConversation = nil
        
        // Delete any created conversation
        if let selected = selectedId {
            let desc = FetchDescriptor<Conversation>()
            let allConversations = try modelContext.fetch(desc)
            if let toDelete = allConversations.first(where: { $0.id == selected }) {
                modelContext.delete(toDelete)
                try modelContext.save()
            }
        }
        
        // When - With existing conversations
        let existingConversation = Conversation(title: "Existing Chat")
        conversations = [existingConversation]
        coordinator.selectedConversation = nil
        
        coordinator.setupInitialConversation(conversations: conversations, in: modelContext)
        
        // Then
        XCTAssertEqual(coordinator.selectedConversation?.title, "Existing Chat")
        
        // Final cleanup
        coordinator.selectedConversation = nil
    }
}
