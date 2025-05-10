//
//
// SwiftAIChatGPT
// MessageInputView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 

import SwiftUI
import SwiftData

struct MessageInputView: View {
    @Binding var text: String
    @State private var height: CGFloat = 40
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder
            if text.isEmpty {
                Text("Type a message...")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
            
            // Growing text editor
            TextView(text: $text, height: $height)
                .frame(minHeight: 40, maxHeight: 200)
                .frame(height: height)
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
}
