//
//
// SwiftAIChatGPT
// Message.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import Foundation
import SwiftData

@Model
final class Message: Identifiable {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var conversation: Conversation?
    
    init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
