//
//
// SwiftAIChatGPT
// VoiceChatCoordinator.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import AVFoundation

@Observable
class VoiceChatCoordinator {
    // State management
    var viewModel: VoiceChatViewModel?
    var visualizationViewModel = AudioVisualizationViewModel()
    var showRetryButton = false
    var allowDismissal = true
    var showSettingsPrompt = false
    
    // Error handling
    private let errorHandler: (AppError) -> Void
    
    init(errorHandler: @escaping (AppError) -> Void) {
        self.errorHandler = errorHandler
    }
    
    func initializeViewModel() {
        // Create view model with custom error handler
        let vm = VoiceChatViewModel(errorHandler: { [weak self] error in
            guard let self = self else { return }
            // Handle on main thread to avoid timing issues
            DispatchQueue.main.async {
                self.handleError(error)
            }
        })
        viewModel = vm
    }
    
    func handleError(_ error: AppError) {
        // For permission errors, update our local state directly
        if case .permissionDenied = error {
            allowDismissal = false
            showSettingsPrompt = true
            
            // We'll still pass the error to the coordinator but clear it immediately
            errorHandler(error)
        } else {
            // For other errors, use normal error handling
            errorHandler(error)
            showRetryButton = true
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func updateVisualizationState() {
        guard let voiceViewModel = viewModel else { return }
        
        if voiceViewModel.isAISpeaking {
            visualizationViewModel.state = .responding
        } else if voiceViewModel.isRecording {
            visualizationViewModel.state = .listening
        } else {
            visualizationViewModel.state = .idle
        }
    }
    
    func toggleRecording() {
        guard let voiceViewModel = viewModel else { return }
        
        if voiceViewModel.isRecording {
            voiceViewModel.stopVoiceChat()
        } else {
            // Clear any previous errors when manually starting
            showRetryButton = false
            
            // Check microphone permissions first synchronously
            let micStatus = voiceViewModel.checkMicrophonePermission()
            if micStatus == .denied {
                voiceViewModel.permissionDenied = true
                voiceViewModel.deniedPermissionType = .microphone
                showSettingsPrompt = true
                allowDismissal = false
                return
            }
            
            // For undetermined or granted, proceed normally
            Task {
                await voiceViewModel.startVoiceChat()
            }
        }
    }
    
    func retryVoiceChat() {
        showRetryButton = false
        Task { [weak self] in
            await self?.viewModel?.startVoiceChat()
        }
    }
    
    func attemptToDismiss() -> Bool {
        if !allowDismissal {
            // Can't dismiss while permissions are denied - provide feedback
            HapticService.error()
            
            // Highlight the issue
            showSettingsPrompt = true
            return false
        } else {
            // Safe to dismiss
            viewModel?.stopVoiceChat()
            visualizationViewModel.reset()
            return true
        }
    }
    
    func statusText() -> String {
        guard let viewModel = viewModel else { return "Initializing..." }
        
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
    
    // Permission retry handling
    func retryAfterPermissionError() {
        guard let viewModel = viewModel else { return }
        
        viewModel.retryAfterPermissionError()
        showSettingsPrompt = false
        allowDismissal = true // Allow dismissal again
        
        Task {
            await viewModel.startVoiceChat()
        }
    }
}
