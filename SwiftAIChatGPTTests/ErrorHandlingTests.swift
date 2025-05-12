//
//
// SwiftAIChatGPTTests
// ErrorHandlingTests.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import XCTest
@testable import SwiftAIChatGPT

final class ErrorHandlingTests: XCTestCase {
    
    func testAppErrorEquality() {
        // Test that AppError enum cases are equatable
        XCTAssertEqual(
            AppError.networkUnavailable,
            AppError.networkUnavailable
        )
        
        XCTAssertEqual(
            AppError.permissionDenied(.microphone),
            AppError.permissionDenied(.microphone)
        )
        
        XCTAssertEqual(
            AppError.saveFailed("Same message"),
            AppError.saveFailed("Same message")
        )
        
        XCTAssertNotEqual(
            AppError.networkUnavailable,
            AppError.timeout
        )
        
        XCTAssertNotEqual(
            AppError.permissionDenied(.microphone),
            AppError.permissionDenied(.speechRecognition)
        )
    }
    
    func testAppErrorDescriptions() {
        // Test error descriptions
        XCTAssertTrue(
            AppError.networkUnavailable.errorDescription?.contains("No internet") ?? false,
            "Network error should mention internet"
        )
        
        XCTAssertTrue(
            AppError.permissionDenied(.microphone).errorDescription?.contains("Microphone") ?? false,
            "Microphone permission error should mention microphone"
        )
        
        XCTAssertTrue(
            AppError.timeout.errorDescription?.contains("timed out") ?? false,
            "Timeout error should mention timing out"
        )
    }
    
    func testErrorStateShowAndClear() {
        // Given
        let errorState = ErrorState()
        XCTAssertFalse(errorState.isShowing)
        XCTAssertNil(errorState.currentError)
        
        // When
        errorState.show(.networkUnavailable)
        
        // Then
        XCTAssertTrue(errorState.isShowing)
        XCTAssertEqual(errorState.currentError, .networkUnavailable)
        XCTAssertTrue(errorState.hasError)
        
        // When
        errorState.clear()
        
        // Then
        XCTAssertFalse(errorState.isShowing)
        XCTAssertNil(errorState.currentError)
        XCTAssertFalse(errorState.hasError)
    }
    
    func testErrorProperties() {
        // Test retryable property
        XCTAssertTrue(AppError.networkUnavailable.isRetryable)
        XCTAssertTrue(AppError.timeout.isRetryable)
        XCTAssertFalse(AppError.permissionDenied(.microphone).isRetryable)
        
        // Test requiresSettings property
        XCTAssertTrue(AppError.permissionDenied(.microphone).requiresSettings)
        XCTAssertFalse(AppError.networkUnavailable.requiresSettings)
    }
}
