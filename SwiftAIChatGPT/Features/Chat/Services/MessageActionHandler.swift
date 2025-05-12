//
//
// SwiftAIChatGPT
// MessageActionHandler.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import Foundation
import SwiftUI

@Observable
class MessageActionHandler {
    private let speechManager = SpeechManager()
    var copiedMessageId: UUID?
    
    var isSpeaking: Bool {
        speechManager.isSpeaking
    }
    
    func copyMessage(_ message: Message) {
        ClipboardService.copyMessage(message.content)
        
        // Show copied state temporarily
        withAnimation {
            copiedMessageId = message.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.copiedMessageId = nil
            }
        }
    }
    
    func toggleSpeech(for message: Message) {
        if speechManager.isSpeaking {
            speechManager.stopSpeaking()
        } else {
            speechManager.speak(message.content)
        }
    }
    
    func stopSpeaking() {
        speechManager.stopSpeaking()
    }
}
