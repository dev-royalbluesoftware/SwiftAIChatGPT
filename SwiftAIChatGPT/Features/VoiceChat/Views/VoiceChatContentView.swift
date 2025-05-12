//
//
// SwiftAIChatGPT
// VoiceChatContentView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//



import SwiftUI
import AVFoundation

struct VoiceChatContentView: View {
    @Bindable var viewModel: VoiceChatViewModel
    @Bindable var coordinator: VoiceChatCoordinator
    
    var body: some View {
        VStack {
            if viewModel.permissionDenied || coordinator.showSettingsPrompt {
                // Permission denied UI
                PermissionDeniedView(
                    permissionType: viewModel.deniedPermissionType,
                    onTryAgain: {
                        coordinator.retryAfterPermissionError()
                    },
                    onOpenSettings: coordinator.openSettings
                )
            } else {
                // Regular voice chat content
                VoiceChatVisualizationContent(
                    viewModel: viewModel,
                    coordinator: coordinator
                )
            }
        }
        .onChange(of: viewModel.isRecording) { _, _ in
            coordinator.updateVisualizationState()
        }
        .onChange(of: viewModel.isAISpeaking) { _, _ in
            coordinator.updateVisualizationState()
        }
        .onChange(of: viewModel.userAudioLevel) { _, newValue in
            if viewModel.isRecording {
                coordinator.visualizationViewModel.updateAudioLevel(newValue)
            }
        }
        .onChange(of: viewModel.aiAudioLevel) { _, newValue in
            if viewModel.isAISpeaking {
                coordinator.visualizationViewModel.updateAudioLevel(newValue)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.permissionDenied)
        .animation(.easeInOut(duration: 0.3), value: coordinator.showSettingsPrompt)
    }
}
