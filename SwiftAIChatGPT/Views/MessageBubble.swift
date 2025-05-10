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
                      // AI message with enhanced markdown support
                      MarkdownView(text: message.content)
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
      
      private func copyMessage() {
          // Copy the rich text version
          if let attributedString = try? NSAttributedString(
              markdown: message.content,
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
              UIPasteboard.general.string = message.content
          }
          
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

  // Enhanced Markdown View with better styling
  struct MarkdownView: View {
      let text: String
      
      var body: some View {
          if let attributedString = try? AttributedString(markdown: text) {
              Text(attributedString)
                  .textSelection(.enabled)
          } else {
              Text(text)
                  .textSelection(.enabled)
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
          
          // Remove markdown formatting for speech
          let plainText = text.replacingOccurrences(of: "**", with: "")
              .replacingOccurrences(of: "*", with: "")
              .replacingOccurrences(of: "#", with: "")
              .replacingOccurrences(of: "`", with: "")
          
          let utterance = AVSpeechUtterance(string: plainText)
          
          // Use a more natural voice if available
          if let voice = AVSpeechSynthesisVoice(language: "en-US") {
              utterance.voice = voice
          }
          
          utterance.rate = 0.52  // Slightly faster for more natural speech
          utterance.pitchMultiplier = 1.0
          utterance.volume = 0.9
          
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

  #Preview {
      VStack(spacing: 20) {
          MessageBubble(message: Message(content: "Hello, how can I help you today?", isUser: false))
          MessageBubble(message: Message(content: "I need help with SwiftUI", isUser: true))
          MessageBubble(message: Message(content: "**SwiftUI** is a powerful framework for building *user interfaces*. Here's what you need to know:\n\n1. Declarative syntax\n2. Live previews\n3. Cross-platform support", isUser: false))
      }
      .padding()
  }
