//
//
// SwiftAIChatGPT
// Conversation.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import Foundation
import SwiftData

@Model
final class Conversation: Identifiable {
    var id: UUID
    var title: String
    var createdAt: Date
    var lastUpdated: Date
    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message]
    
    init(title: String = "New Conversation", createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.lastUpdated = createdAt
        self.messages = []
    }
}
