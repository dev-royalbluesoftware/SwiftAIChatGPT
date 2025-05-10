//
//
// SwiftAIChatGPT
// MessageBubble.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import SwiftUI
import SwiftData
import AVFoundation

struct MessageBubble: View {
    let message: Message
       @State private var copiedText: Bool = false
       @State private var isPlaying: Bool = false
       
       // Speech synthesizer must be a property, not a local variable
       @StateObject private var speechManager = SpeechManager()
       
       var body: some View {
           HStack {
               if message.isUser { Spacer() }
               
               VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                   // Render markdown for AI messages, plain text for user
                   if message.isUser {
                       Text(message.content)
                           .padding(.horizontal, 16)
                           .padding(.vertical, 10)
                           .background(
                               RoundedRectangle(cornerRadius: 20)
                                   .fill(Color.blue)
                           )
                           .foregroundColor(.white)
                   } else {
                       // AI message with markdown support
                       Text(renderMarkdown(message.content))
                           .padding(.horizontal, 16)
                           .padding(.vertical, 10)
                           .background(
                               RoundedRectangle(cornerRadius: 20)
                                   .fill(Color(.systemGray5))
                           )
                           .foregroundColor(.primary)
                   }
                   
                   if !message.isUser {
                       // Action buttons for AI messages
                       HStack(spacing: 12) {
                           Button(action: copyMessage) {
                               HStack(spacing: 4) {
                                   Image(systemName: copiedText ? "checkmark" : "doc.on.doc")
                                   Text(copiedText ? "Copied" : "Copy")
                               }
                               .font(.caption)
                           }
                           .buttonStyle(PlainButtonStyle())
                           
                           Button(action: playMessage) {
                               HStack(spacing: 4) {
                                   Image(systemName: speechManager.isSpeaking ? "stop.fill" : "play.fill")
                                   Text(speechManager.isSpeaking ? "Stop" : "Play")
                               }
                               .font(.caption)
                           }
                           .buttonStyle(PlainButtonStyle())
                       }
                       .foregroundColor(.gray)
                   }
               }
               .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
               
               if !message.isUser { Spacer() }
           }
           .onChange(of: speechManager.isSpeaking) { oldValue, newValue in
               isPlaying = newValue
           }
       }
       
       private func renderMarkdown(_ text: String) -> AttributedString {
           do {
               // Using markdown options for basic formatting
               var attributedString = try AttributedString(markdown: text)
               return attributedString
           } catch {
               // Fallback to plain text
               return AttributedString(text)
           }
       }
       
       private func copyMessage() {
           UIPasteboard.general.string = message.content
           
           // Haptic feedback
           let impact = UIImpactFeedbackGenerator(style: .light)
           impact.impactOccurred()
           
           // Show copied state temporarily
           withAnimation {
               copiedText = true
           }
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
               withAnimation {
                   copiedText = false
               }
           }
       }
       
       private func playMessage() {
           if speechManager.isSpeaking {
               speechManager.stopSpeaking()
           } else {
               speechManager.speak(message.content)
           }
       }
   }

   // Speech Manager to handle AVSpeechSynthesizer properly
   class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
       @Published var isSpeaking = false
       private let synthesizer = AVSpeechSynthesizer()
       
       override init() {
           super.init()
           synthesizer.delegate = self
       }
       
       func speak(_ text: String) {
           // Stop any current speech
           if synthesizer.isSpeaking {
               synthesizer.stopSpeaking(at: .immediate)
           }
           
           let utterance = AVSpeechUtterance(string: text)
           utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
           utterance.rate = 0.5
           utterance.pitchMultiplier = 1.0
           utterance.volume = 0.8
           
           synthesizer.speak(utterance)
           isSpeaking = true
       }
       
       func stopSpeaking() {
           synthesizer.stopSpeaking(at: .immediate)
           isSpeaking = false
       }
       
       // MARK: - AVSpeechSynthesizerDelegate
       
       func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
           DispatchQueue.main.async {
               self.isSpeaking = true
           }
       }
       
       func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
           DispatchQueue.main.async {
               self.isSpeaking = false
           }
       }
       
       func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
           DispatchQueue.main.async {
               self.isSpeaking = false
           }
       }
   }
