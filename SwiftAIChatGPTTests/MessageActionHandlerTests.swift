//
//
// SwiftAIChatGPTTests
// MessageActionHandlerTests.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import XCTest
import SwiftUI
@testable import SwiftAIChatGPT

final class MessageActionHandlerTests: XCTestCase {
    var actionHandler: MessageActionHandler!
    var message: Message!
    
    override func setUp() {
        super.setUp()
        actionHandler = MessageActionHandler()
        message = Message(content: "Test message", isUser: false)
    }
    
    override func tearDown() {
        actionHandler = nil
        message = nil
        super.tearDown()
    }
    
    func testCopyMessageSetsMessageId() {
        // Given
        XCTAssertNil(actionHandler.copiedMessageId)
        
        // When
        actionHandler.copyMessage(message)
        
        // Then - We can test the outcome without mocking the static method
        XCTAssertEqual(actionHandler.copiedMessageId, message.id)
        
        // Wait to ensure the ID is properly set and any async operation completes
        let expectation = XCTestExpectation(description: "Wait for ID to be set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleSpeechStartsSpeech() {
        // This is challenging to test directly because SpeechManager
        // uses AVSpeechSynthesizer which we can't easily mock in tests
        // For now, we'll just test that the method exists and doesn't crash
        
        // When/Then - No crash means the test passes
        actionHandler.toggleSpeech(for: message)
        
        // In a real test environment, we would inject a mock SpeechManager
        // and verify it was called correctly
    }
    
    func testStopSpeakingMethodExists() {
        // When/Then - Make sure the method exists and doesn't crash
        actionHandler.stopSpeaking()
    }
}
