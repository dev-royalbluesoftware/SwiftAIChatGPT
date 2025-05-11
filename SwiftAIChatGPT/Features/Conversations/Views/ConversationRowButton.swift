//
//
// SwiftAIChatGPT
// ConversationRowButton.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 

import SwiftUI

struct ConversationRowButton: View {
    let conversation: Conversation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                ConversationRow(conversation: conversation)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
