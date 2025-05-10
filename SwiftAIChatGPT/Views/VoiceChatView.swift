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

struct VoiceChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = VoiceChatViewModel()
    @State private var visualizationState: AudioVisualizationState = .idle
    @State private var audioLevel: Float = 0.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [.black, Color(white: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Header
                    HStack {
                        Button(action: {
                            viewModel.stopVoiceChat()
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding()
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Audio visualization
                    AudioVisualizationContainer(
                        state: $visualizationState,
                        audioLevel: $audioLevel,
                        isRecording: $viewModel.isRecording
                    )
                    .frame(height: 200)
                    .padding()
                    
                    Spacer()
                    
                    // Status text
                    Text(statusText)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                        .padding(.bottom, 20)
                    
                    // Transcribed text display
                    if !viewModel.transcribedText.isEmpty {
                        ScrollView {
                            Text(viewModel.transcribedText)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.3))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Main action button
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : Color.white)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 35))
                                .foregroundColor(viewModel.isRecording ? .white : .black)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .preferredColorScheme(.dark)
            .alert("Permission Required", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel") {
                    viewModel.errorMessage = nil
                    dismiss()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onChange(of: viewModel.isRecording) { oldValue, newValue in
            updateVisualizationState(isRecording: newValue)
        }
        .onChange(of: viewModel.isProcessing) { oldValue, newValue in
            if newValue {
                visualizationState = .responding
                // Simulate audio level changes
                simulateAudioLevel()
            }
        }
    }
    
    private var statusText: String {
        switch visualizationState {
        case .idle:
            return "Tap to start speaking"
        case .listening:
            return "Listening..."
        case .responding:
            return "AI is responding..."
        }
    }
    
    private func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stopVoiceChat()
        } else {
            Task {
                await viewModel.startVoiceChat()
            }
        }
    }
    
    private func updateVisualizationState(isRecording: Bool) {
        withAnimation {
            visualizationState = isRecording ? .listening : .idle
        }
    }
    
    private func simulateAudioLevel() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if visualizationState == .responding {
                // Simulate varying audio levels
                audioLevel = Float.random(in: 0.3...0.8)
            } else {
                timer.invalidate()
                audioLevel = 0.0
            }
        }
    }
}

#Preview {
    VoiceChatView()
}
