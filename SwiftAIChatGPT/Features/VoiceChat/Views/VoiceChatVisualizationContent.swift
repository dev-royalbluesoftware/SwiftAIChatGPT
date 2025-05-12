//
//
// SwiftAIChatGPT
// VoiceChatVisualizationContent.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//



import SwiftUI
import AVFoundation

struct VoiceChatVisualizationContent: View {
    let viewModel: VoiceChatViewModel
    @Bindable var coordinator: VoiceChatCoordinator
    
    var body: some View {
        VStack {
            Spacer()
            
            // Audio visualization
            AudioVisualizationContainer(
                state: .init(
                    get: { coordinator.visualizationViewModel.state },
                    set: { coordinator.visualizationViewModel.state = $0 }
                ),
                audioLevel: .init(
                    get: { coordinator.visualizationViewModel.audioLevel },
                    set: { coordinator.visualizationViewModel.audioLevel = $0 }
                ),
                isRecording: .init(
                    get: { viewModel.isRecording },
                    set: { _ in }
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .padding(.vertical)
            .padding(.horizontal, 0)
            
            Spacer()
            
            // Status text
            Text(coordinator.statusText())
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
                .padding(.bottom, 20)
            
            // Transcribed text and AI response
            VoiceChatTranscriptionView(viewModel: viewModel)
            
            // Main action button
            Button(action: {
                coordinator.toggleRecording()
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.white)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 35))
                        .foregroundColor(viewModel.isRecording ? .white : .black)
                }
            }
            .disabled(viewModel.isProcessing || viewModel.isAISpeaking)
            .padding(.bottom, 50)
            
            // Add a manual retry button if errors occur
            if coordinator.showRetryButton {
                Button(action: {
                    coordinator.retryVoiceChat()
                }) {
                    Label("Retry Voice Chat", systemImage: "arrow.clockwise")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
        }
    }
}
