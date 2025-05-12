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
    @Environment(\.appCoordinator) private var appCoordinator
    @State private var coordinator: VoiceChatCoordinator?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.black, Color(white: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if let coordinator = coordinator {
                    if let voiceViewModel = coordinator.viewModel {
                        // Main content
                        VoiceChatContentView(
                            viewModel: voiceViewModel,
                            coordinator: coordinator
                        )
                    } else {
                        ProgressView()
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            initializeCoordinator()
                        }
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if let coordinator = coordinator {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            if coordinator.attemptToDismiss() {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    if !coordinator.allowDismissal {
                        ToolbarItem(placement: .principal) {
                            Text("Permission required")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(coordinator?.allowDismissal == false)
        .onChange(of: appCoordinator.errorState.isShowing) { _, newValue in
            if newValue, let error = appCoordinator.errorState.currentError, let coordinator = coordinator {
                coordinator.handleError(error)
                appCoordinator.errorState.clear()
            }
        }
        .onChange(of: coordinator?.viewModel?.permissionDenied) { _, newValue in
            guard let coordinator = coordinator else { return }
            
            DispatchQueue.main.async {
                coordinator.allowDismissal = !(newValue == true)
                
                if newValue == true {
                    appCoordinator.errorState.clear()
                    coordinator.showSettingsPrompt = true
                }
            }
        }
    }
    
    private func initializeCoordinator() {
        // Create a new coordinator
        let newCoordinator = VoiceChatCoordinator(errorHandler: { [weak appCoordinator] error in
            // We'll handle the error in the app coordinator
            DispatchQueue.main.async {
                appCoordinator?.handleError(error)
            }
        })
        
        // Initialize the view model
        newCoordinator.initializeViewModel()
        
        // Set the coordinator
        self.coordinator = newCoordinator
    }
}
