//
//
// SwiftAIChatGPT
// VoiceChatView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import AVFoundation
// Views/VoiceChatView.swift
import SwiftUI
import AVFoundation

struct VoiceChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = VoiceChatViewModel()
    @State private var animationPhase = 0.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Visual representation of audio
                    if viewModel.isRecording {
                        AudioVisualizerView(isRecording: $viewModel.isRecording)
                    } else {
                        IdleAudioView(animationPhase: $animationPhase)
                    }
                    
                    Spacer()
                    
                    // Transcribed text display
                    if !viewModel.transcribedText.isEmpty {
                        Text(viewModel.transcribedText)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.7))
                            )
                            .padding(.horizontal)
                    }
                    
                    // Control buttons
                    HStack(spacing: 40) {
                        // Cancel button
                        Button(action: {
                            viewModel.stopVoiceChat()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                        }
                        
                        // Record/Stop button
                        Button(action: {
                            if viewModel.isRecording {
                                viewModel.stopVoiceChat()
                            } else {
                                Task {
                                    await viewModel.startVoiceChat()
                                }
                            }
                        }) {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(viewModel.isRecording ? .red : .white)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
}

// Simple visualization views (placeholders for now)
struct AudioVisualizerView: View {
    @Binding var isRecording: Bool
    
    var body: some View {
        // Placeholder for audio visualization
        HStack(spacing: 4) {
            ForEach(0..<20) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 10, height: CGFloat.random(in: 20...100))
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
            }
        }
        .frame(height: 100)
    }
}

struct IdleAudioView: View {
    @Binding var animationPhase: Double
    
    var body: some View {
        // Placeholder for idle state
        Circle()
            .stroke(Color.white.opacity(0.5), lineWidth: 4)
            .frame(width: 150, height: 150)
            .scaleEffect(animationPhase)
            .opacity(2 - animationPhase)
    }
}
