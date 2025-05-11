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
                            visualizationViewModel.reset()
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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(voiceViewModel.transcribedText)
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
                    if !voiceViewModel.aiResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(voiceViewModel.aiResponse)
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
                    .disabled(voiceViewModel.isProcessing || voiceViewModel.isAISpeaking)
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
            .onChange(of: voiceViewModel.isRecording) { _, newValue in
                visualizationViewModel.updateState(isRecording: newValue, isAISpeaking: voiceViewModel.isAISpeaking)
            }
            .onChange(of: voiceViewModel.isAISpeaking) { _, newValue in
                visualizationViewModel.updateState(isRecording: voiceViewModel.isRecording, isAISpeaking: newValue)
            }
            .onChange(of: voiceViewModel.userAudioLevel) { _, newValue in
                if voiceViewModel.isRecording {
                    visualizationViewModel.updateAudioLevel(newValue)
                }
            }
            .onChange(of: voiceViewModel.aiAudioLevel) { _, newValue in
                if voiceViewModel.isAISpeaking {
                    visualizationViewModel.updateAudioLevel(newValue)
                }
            }
        }
    }
    
    private var statusText: String {
        if voiceViewModel.isProcessing {
            return "Processing..."
        } else if voiceViewModel.isAISpeaking {
            return "AI is responding..."
        } else if voiceViewModel.isRecording {
            return "Listening..."
        } else {
            return "Tap to start speaking"
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
