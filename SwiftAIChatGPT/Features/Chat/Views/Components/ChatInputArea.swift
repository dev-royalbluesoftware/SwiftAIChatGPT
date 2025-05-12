//
//
// SwiftAIChatGPT
// ChatInputArea.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI

struct ChatInputArea: View {
    @Environment(\.appCoordinator) private var coordinator
    @Bindable var viewModel: ChatViewModel
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            MessageInputView(text: $viewModel.messageText)
            
            Button(action: {
                coordinator.showVoiceChat()
            }) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            .alignmentGuide(.bottom) { d in d[.bottom] }
            
            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                Image(systemName: "paperplane.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.messageText.isEmpty ? .gray : .blue)
            }
            .disabled(viewModel.messageText.isEmpty || viewModel.isThinking)
            .alignmentGuide(.bottom) { d in d[.bottom] }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
