//
//
// SwiftAIChatGPT
// MarkdownView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 

import SwiftUI
import SwiftData

struct MarkdownView: View {
    let text: String
    
    var body: some View {
        if let attributedString = try? AttributedString(
            markdown: self.text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            Text(attributedString)
                .textSelection(.enabled)
        } else {
            Text(self.text)
                .textSelection(.enabled)
        }
    }
}
