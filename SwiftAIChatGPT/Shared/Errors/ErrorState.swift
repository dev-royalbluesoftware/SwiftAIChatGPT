//
//
// SwiftAIChatGPT
// ErrorState.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import SwiftUI

@Observable
class ErrorState {
    var currentError: AppError?
    var isShowing = false
    
    func show(_ error: AppError) {
        self.currentError = error
        self.isShowing = true
    }
    
    func clear() {
        self.currentError = nil
        self.isShowing = false
    }
    
    var hasError: Bool {
        currentError != nil
    }
}

// Global error handling modifier
struct ErrorHandlerModifier: ViewModifier {
    @Bindable var errorState: ErrorState
    var onRetry: (() -> Void)?
    var onSettings: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: $errorState.isShowing,
                presenting: errorState.currentError
            ) { error in
                // Primary button
                Button("OK") {
                    // For permission errors in VoiceChatView, we don't auto-dismiss
                    // because we're showing custom UI
                    if case .permissionDenied = error {
                        // Don't clear if we're showing a dedicated UI that needs the error info
                        // The dedicated UI will call errorState.clear() when appropriate
                    } else {
                        errorState.clear()
                    }
                }
                
                // Secondary button based on error type
                if error.isRetryable {
                    Button("Retry") {
                        errorState.clear()
                        onRetry?()
                    }
                }
                
                if error.requiresSettings {
                    Button("Settings") {
                        errorState.clear()
                        onSettings?()
                    }
                }
            } message: { error in
                VStack {
                    Text(error.errorDescription ?? "An error occurred")
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func errorHandler(
        _ errorState: ErrorState,
        onRetry: (() -> Void)? = nil,
        onSettings: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorHandlerModifier(
            errorState: errorState,
            onRetry: onRetry,
            onSettings: onSettings
        ))
    }
}
