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
    @State private var voiceViewModel = VoiceChatViewModel()
    @State private var visualizationViewModel = AudioVisualizationViewModel()
    
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
                            voiceViewModel.stopVoiceChat()
                            visualizationViewModel.stopSimulation()
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
                        state: $visualizationViewModel.state,
                        audioLevel: $visualizationViewModel.audioLevel,
                        isRecording: $voiceViewModel.isRecording
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
                    if !voiceViewModel.transcribedText.isEmpty {
                        ScrollView {
                            Text(voiceViewModel.transcribedText)
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
                                .fill(voiceViewModel.isRecording ? Color.red : Color.white)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: voiceViewModel.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 35))
                                .foregroundColor(voiceViewModel.isRecording ? .white : .black)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .preferredColorScheme(.dark)
            .alert("Permission Required", isPresented: .constant(voiceViewModel.errorMessage != nil)) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel") {
                    voiceViewModel.errorMessage = nil
                    dismiss()
                }
            } message: {
                if let errorMessage = voiceViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onChange(of: voiceViewModel.isRecording) { oldValue, newValue in
            visualizationViewModel.updateState(isRecording: newValue)
        }
        .onChange(of: voiceViewModel.isProcessing) { oldValue, newValue in
            if newValue {
                visualizationViewModel.setResponding()
            }
        }
    }
    
    private var statusText: String {
        switch visualizationViewModel.state {
        case .idle:
            return "Tap to start speaking"
        case .listening:
            return "Listening..."
        case .responding:
            return "AI is responding..."
        }
    }
    
    private func toggleRecording() {
        if voiceViewModel.isRecording {
            voiceViewModel.stopVoiceChat()
        } else {
            Task {
                await voiceViewModel.startVoiceChat()
            }
        }
    }
}

#Preview {
    VoiceChatView()
}
