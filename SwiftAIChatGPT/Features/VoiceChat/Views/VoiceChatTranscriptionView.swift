//
//
// SwiftAIChatGPT
// VoiceChatTranscriptionView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//



import SwiftUI
import AVFoundation

struct VoiceChatTranscriptionView: View {
    let viewModel: VoiceChatViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Transcribed text display
            if !viewModel.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(viewModel.transcribedText)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal)
            }
            
            // AI Response display
            if !viewModel.aiResponse.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(viewModel.aiResponse)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue.opacity(0.2))
                )
                .padding(.horizontal)
            }
        }
    }
}
