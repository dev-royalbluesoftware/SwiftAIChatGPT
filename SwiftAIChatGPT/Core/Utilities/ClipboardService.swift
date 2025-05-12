//
//
// SwiftAIChatGPT
// ClipboardService.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import Foundation
import SwiftUI

struct ClipboardService {
    static func copyMessage(_ content: String) {
        // Copy the rich text version
        if let attributedString = try? NSAttributedString(
            markdown: content,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            UIPasteboard.general.setValue(
                attributedString.string,
                forPasteboardType: "public.utf8-plain-text"
            )
            
            // Also copy as rich text if possible
            if let rtfData = try? attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) {
                UIPasteboard.general.setValue(
                    rtfData,
                    forPasteboardType: "public.rtf"
                )
            }
        } else {
            // Fallback to plain text
            UIPasteboard.general.string = content
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
