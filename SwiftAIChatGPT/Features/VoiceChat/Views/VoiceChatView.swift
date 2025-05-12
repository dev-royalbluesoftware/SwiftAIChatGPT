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
    @State private var allowDismissal = true
    @State private var showSettingsPrompt = false
    
    var body: some View {
        ZStack {
            // Main content wrapped in a NavigationStack
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
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            attemptToDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    if !allowDismissal {
                        ToolbarItem(placement: .principal) {
                            Text("Permission required")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(!allowDismissal)
        // Use custom error handling to avoid alert conflicts
        .onChange(of: coordinator.errorState.isShowing) { _, newValue in
            if newValue, let error = coordinator.errorState.currentError {
                handleError(error)
            }
        }
        // Listen for permission changes
        .onChange(of: voiceViewModel?.permissionDenied) { _, newValue in
            // Schedule this work to happen after any current presentation
            DispatchQueue.main.async {
                // Block dismissal when permissions are denied
                allowDismissal = !(newValue == true)
                
                // Debug
                print("Permission denied changed: \(String(describing: newValue)), allowDismissal: \(allowDismissal)")
                
                // If permission was denied, make sure we show the custom UI instead of an alert
                if newValue == true {
                    coordinator.errorState.clear() // Clear any alerts to avoid conflicts
                    showSettingsPrompt = true
                }
            }
        }
    }
    
    private func handleError(_ error: AppError) {
        // For permission errors, we'll handle them with our custom UI
        if case .permissionDenied = error {
            DispatchQueue.main.async {
                allowDismissal = false
                showSettingsPrompt = true
                coordinator.errorState.clear() // Clear the error to avoid showing standard alert
            }
        } else {
            // For other errors, show retry button
            showRetryButton = true
        }
    }
    
    private func initializeViewModel() {
        // Create view model with custom error handler
        let vm = VoiceChatViewModel(errorHandler: { error in
            // Handle on main thread to avoid timing issues
            DispatchQueue.main.async {
                // For permission errors, update our local state directly
                if case .permissionDenied = error {
                    allowDismissal = false
                    showSettingsPrompt = true
                    
                    // We'll still pass the error to the coordinator but clear it immediately
                    // to avoid showing the standard alert
                    self.coordinator.handleError(error)
                    self.coordinator.errorState.clear()
                } else {
                    // For other errors, use normal error handling
                    self.coordinator.handleError(error)
                }
            }
        })
        voiceViewModel = vm
    }
    
    private func attemptToDismiss() {
        if !allowDismissal {
            // Can't dismiss while permissions are denied - provide feedback
            HapticService.error()
            
            // Highlight the issue
            showSettingsPrompt = true
        } else {
            // Safe to dismiss
            voiceViewModel?.stopVoiceChat()
            visualizationViewModel.reset()
            dismiss()
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    @ViewBuilder
    private func voiceChatContent(voiceViewModel: VoiceChatViewModel) -> some View {
        @Bindable var voiceVM = voiceViewModel
        
        VStack {
            if voiceViewModel.permissionDenied || showSettingsPrompt {
                // Show permission denied view using the extracted component
                PermissionDeniedView(
                    permissionType: voiceViewModel.deniedPermissionType,
                    onTryAgain: {
                        // Try again - this will re-request permission if it was previously "undetermined"
                        voiceViewModel.retryAfterPermissionError()
                        coordinator.clearError() // Clear any displayed error
                        showSettingsPrompt = false
                        allowDismissal = true // Allow dismissal again
                        
                        Task {
                            await voiceViewModel.startVoiceChat()
                        }
                    },
                    onOpenSettings: openSettings
                )
            } else {
                // Regular voice chat content
                Spacer()
                
                // Audio visualization
                AudioVisualizationContainer(
                    state: $visualizationViewModel.state,
                    audioLevel: $visualizationViewModel.audioLevel,
                    isRecording: $voiceVM.isRecording
                )
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .padding(.vertical)
                .padding(.horizontal, 0) // Remove horizontal padding to allow full width
                
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
        .animation(.easeInOut(duration: 0.3), value: voiceViewModel.permissionDenied)
        .animation(.easeInOut(duration: 0.3), value: showSettingsPrompt)
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
            
            // We'll check microphone permissions first synchronously
            // to immediately show our custom UI rather than waiting for the alert
            let micStatus = voiceViewModel.checkMicrophonePermission()
            if micStatus == .denied {
                voiceViewModel.permissionDenied = true
                voiceViewModel.deniedPermissionType = .microphone
                showSettingsPrompt = true
                allowDismissal = false
                
                // Don't call startVoiceChat in this case
                return
            }
            
            // For undetermined or granted, proceed normally
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
