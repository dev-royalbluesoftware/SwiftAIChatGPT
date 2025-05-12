//
//
// SwiftAIChatGPTTests
// ChatViewModelTests.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import XCTest
import SwiftData
@testable import SwiftAIChatGPT

@MainActor
final class FinalChatViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var conversation: Conversation!
    var viewModel: ChatViewModel!
    var networkMonitor: NetworkMonitor!
    var networkService: MockNetworkService!
    var messageManager: MessageManager!
    var errorHandlerCalled = false
    var capturedError: AppError?
    
    @MainActor
    override func setUp() {
        super.setUp()
        
        // Reset state for each test
        errorHandlerCalled = false
        capturedError = nil
        
        // Set up in-memory SwiftData container
        let schema = Schema([Conversation.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContext = modelContainer.mainContext
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
        
        // Set up other dependencies
        conversation = Conversation(title: "Test Conversation")
        modelContext.insert(conversation)
        try? modelContext.save()
        
        networkMonitor = NetworkMonitor()
        networkService = MockNetworkService(networkMonitor: networkMonitor)
        
        messageManager = MessageManager(
            modelContext: modelContext,
            errorHandler: { [weak self] error in
                self?.errorHandlerCalled = true
                self?.capturedError = error
            }
        )
        
        // Create view model with error handler
        viewModel = ChatViewModel(
            conversation: conversation,
            modelContext: modelContext,
            networkMonitor: networkMonitor,
            networkService: networkService,
            errorHandler: { [weak self] error in
                self?.errorHandlerCalled = true
                self?.capturedError = error
            }
        )
    }
    
    @MainActor
    override func tearDown() {
        // Clean up to avoid dangling references
        viewModel = nil
        
        // Delete messages first
        for message in conversation.messages {
            modelContext.delete(message)
        }
        try? modelContext.save()
        
        // Then delete conversation
        modelContext.delete(conversation)
        try? modelContext.save()
        
        conversation = nil
        messageManager = nil
        networkMonitor = nil
        networkService = nil
        modelContext = nil
        modelContainer = nil
        
        super.tearDown()
    }
    
    // TEST APPROACH: We're going to test just the user message part using directly exposed components
    // instead of the full async flow
    
    @MainActor
    func testUserMessageAddedToConversation() throws {
        // GIVEN: A message manager and conversation
        XCTAssertEqual(conversation.messages.count, 0, "Conversation should start with 0 messages")
        
        // WHEN: We add a user message via the manager
        let userMessage = Message(content: "Test user message", isUser: true)
        messageManager.addMessage(userMessage, to: conversation)
        
        // Save to ensure persistence
        try modelContext.save()
        
        // THEN: The conversation should have exactly 1 message
        XCTAssertEqual(conversation.messages.count, 1, "Should have 1 message")
        XCTAssertEqual(conversation.messages.first?.content, "Test user message")
        XCTAssertEqual(conversation.messages.first?.isUser, true)
    }
    
    @MainActor
    func testNetworkUnavailableTriggesError() async {
        // This test doesn't depend on the message flow
        // It just tests error handling
        
        // GIVEN: No network connection
        viewModel.messageText = "Test message"
        networkMonitor.isConnected = false
        
        // WHEN: We call sendMessage
        await viewModel.sendMessage()
        
        // THEN: Error handler should be called with network error
        XCTAssertTrue(errorHandlerCalled, "Error handler should be called")
        XCTAssertEqual(capturedError, .networkUnavailable, "Error should be network unavailable")
    }
    
    @MainActor
    func testThinkingStateCanBeToggled() {
        // Given - thinking is initially false
        XCTAssertFalse(viewModel.isThinking)
        
        // When - we set it to true
        viewModel.isThinking = true
        
        // Then - it should be true
        XCTAssertTrue(viewModel.isThinking)
        
        // And when we set it back to false
        viewModel.isThinking = false
        
        // Then - it should be false again
        XCTAssertFalse(viewModel.isThinking)
    }
}

// MARK: - Mock Classes

class MockNetworkService: NetworkService {
    var mockResponse: String?
    var shouldThrowError = false
    var completionHandler: (() -> Void)?
    
    override func fetchAIResponse(prompt: String) async throws -> String {
        if shouldThrowError {
            throw AppError.apiError("Mock error")
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // If there's a completion handler, call it
        completionHandler?()
        
        return mockResponse ?? "Mock response"
    }
}
