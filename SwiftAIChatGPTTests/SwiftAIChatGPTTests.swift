//
//
// SwiftAIChatGPTTests
// SwiftAIChatGPTTests.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import XCTest
@testable import SwiftAIChatGPT

final class SwiftAIChatGPTTests: XCTestCase {
    
    // Simple test to verify the test suite is running
    func testExample() {
        XCTAssertTrue(true, "Basic test passes")
    }
    
    // Performance test example
    func testPerformanceExample() {
        self.measure {
            // Put code you want to measure here
            for _ in 1...1000 {
                _ = Conversation(title: "Performance Test")
            }
        }
    }
}
