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
    @Environment(\.appCoordinator) private var coordinator
    @State private var voiceViewModel: VoiceChatViewModel?
    @State private var visualizationViewModel = AudioVisualizationViewModel()
    @State private var showRetryButton = false
    
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
                
                if let voiceViewModel = voiceViewModel {
                    voiceChatContent(voiceViewModel: voiceViewModel)
                } else {
                    ProgressView()
                        .onAppear {
                            initializeViewModel()
                        }
                }
            }
            .preferredColorScheme(.dark)
        }
        .errorHandler(coordinator.errorState) {
            // Show retry button when error occurs
            showRetryButton = true
        }
    }
    
    private func initializeViewModel() {
        let vm = VoiceChatViewModel(errorHandler: { error in
            coordinator.handleError(error)
        })
        voiceViewModel = vm
    }
    
    @ViewBuilder
    private func voiceChatContent(voiceViewModel: VoiceChatViewModel) -> some View {
        @Bindable var voiceVM = voiceViewModel
        
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
                isRecording: $voiceVM.isRecording
            )
            .frame(height: 200)
            .padding()
            
            Spacer()
            
            // Status text
            Text(statusText(for: voiceViewModel))
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
            Button(action: {
                toggleRecording(voiceViewModel: voiceViewModel)
            }) {
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
            
            // Add a manual retry button if errors occur
            if showRetryButton {
                Button(action: {
                    showRetryButton = false
                    Task {
                        await voiceViewModel.startVoiceChat()
                    }
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
        .onChange(of: voiceViewModel.isRecording) { _, newValue in
            updateVisualizationState(voiceViewModel: voiceViewModel)
        }
        .onChange(of: voiceViewModel.isAISpeaking) { _, newValue in
            updateVisualizationState(voiceViewModel: voiceViewModel)
        }
        .onChange(of: voiceViewModel.userAudioLevel) { _, newValue in
            // Throttle audio level updates to visualization
            if voiceViewModel.isRecording {
                visualizationViewModel.updateAudioLevel(newValue)
            }
        }
        .onChange(of: voiceViewModel.aiAudioLevel) { _, newValue in
            // Throttle audio level updates to visualization
            if voiceViewModel.isAISpeaking {
                visualizationViewModel.updateAudioLevel(newValue)
            }
        }
    }
    
    private func statusText(for viewModel: VoiceChatViewModel) -> String {
        if viewModel.isProcessing {
            return "Processing..."
        } else if viewModel.isAISpeaking {
            return "AI is responding..."
        } else if viewModel.isRecording {
            return "Listening..."
        } else {
            return "Tap to start speaking"
        }
    }
    
    private func updateVisualizationState(voiceViewModel: VoiceChatViewModel) {
        if voiceViewModel.isAISpeaking {
            visualizationViewModel.state = .responding
        } else if voiceViewModel.isRecording {
            visualizationViewModel.state = .listening
        } else {
            visualizationViewModel.state = .idle
        }
    }
    
    private func toggleRecording(voiceViewModel: VoiceChatViewModel) {
        if voiceViewModel.isRecording {
            voiceViewModel.stopVoiceChat()
        } else {
            // Clear any previous errors when manually starting
            showRetryButton = false
            Task {
                await voiceViewModel.startVoiceChat()
            }
        }
    }
}

#Preview {
    VoiceChatView()
        .withAppCoordinator(.makePreview())
}
