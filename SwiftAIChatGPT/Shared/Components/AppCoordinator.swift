//
//
// SwiftAIChatGPT
// AppCoordinator.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import SwiftUI
import SwiftData

@Observable
final class AppCoordinator {
    // MARK: - Navigation State
    var selectedConversation: Conversation?
    var showingConversationList = false
    var showingVoiceChat = false
    
    // MARK: - Error Handling
    let errorState = ErrorState()
    
    // MARK: - Shared Services
    let networkMonitor = NetworkMonitor()
    let networkService: NetworkService
    
    // MARK: - Initialization
    
    init() {
        self.networkService = NetworkService(networkMonitor: networkMonitor)
    }
    
    // MARK: - Navigation Methods
    
    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
        showingConversationList = false
    }
    
    func showConversationList() {
        showingConversationList = true
    }
    
    func showVoiceChat() {
        showingVoiceChat = true
    }
    
    func dismissVoiceChat() {
        showingVoiceChat = false
    }
    
    // MARK: - Conversation Management
    
    func createNewConversation(in modelContext: ModelContext) -> Conversation? {
        do {
            let conversation = Conversation()
            modelContext.insert(conversation)
            try modelContext.save()
            selectConversation(conversation)
            return conversation
        } catch {
            handleError(.saveFailed("Could not create new conversation"))
            return nil
        }
    }
    
    func deleteConversation(_ conversation: Conversation, from modelContext: ModelContext) {
        // If deleting the selected conversation, clear the selection
        if conversation.id == selectedConversation?.id {
            selectedConversation = nil
        }
        
        modelContext.delete(conversation)
        
        do {
            try modelContext.save()
        } catch {
            handleError(.saveFailed("Could not delete conversation"))
        }
    }
    
    func updateConversationTitle(_ conversation: Conversation, title: String, in modelContext: ModelContext) {
        do {
            conversation.title = title
            conversation.lastUpdated = Date()
            try modelContext.save()
        } catch {
            handleGenericError(error, context: "Failed to update conversation")
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: AppError) {
        errorState.show(error)
    }
    
    func handleGenericError(_ error: Error, context: String) {
        let appError = AppError.unknown("\(context): \(error.localizedDescription)")
        errorState.show(appError)
    }
    
    func clearError() {
        errorState.clear()
    }
    
    // MARK: - Initial Setup
    
    func setupInitialConversation(conversations: [Conversation], in modelContext: ModelContext) {
        if conversations.isEmpty {
            // Create welcome conversation
            let conversation = Conversation(title: "Welcome Chat")
            modelContext.insert(conversation)
            do {
                try modelContext.save()
                selectedConversation = conversation
            } catch {
                handleGenericError(error, context: "Failed to create initial conversation")
            }
        } else if selectedConversation == nil {
            selectedConversation = conversations.first
        }
    }
    
    // MARK: - State Management
    
    func resetForNewConversation() {
        errorState.clear()
    }
    
    // MARK: - Network and API Handling
    
    func fetchAIResponse(for prompt: String) async -> Result<String, AppError> {
        do {
            let response = try await networkService.fetchAIResponse(prompt: prompt)
            return .success(response)
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    // MARK: - Additional Methods for Refactoring
    
    func handleConversationsChange(_ newConversations: [Conversation]) {
        if let selected = selectedConversation,
           !newConversations.contains(where: { $0.id == selected.id }) {
            selectedConversation = nil
        }
    }
    
    func handleRetry(modelContext: ModelContext) {
        // Implement retry logic based on the current error
        if let error = errorState.currentError {
            switch error {
            case .networkUnavailable:
                // Network errors might resolve themselves, just clear
                clearError()
            case .saveFailed:
                // Retry save operation
                if let conversation = selectedConversation {
                    do {
                        try modelContext.save()
                    } catch {
                        handleGenericError(error, context: "Retry save")
                    }
                }
            default:
                clearError()
            }
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Environment Support
    
    static func makePreview() -> AppCoordinator {
        let coordinator = AppCoordinator()
        coordinator.selectedConversation = Conversation(title: "Preview Chat")
        return coordinator
    }
}

// MARK: - Environment Key

private struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue = AppCoordinator()
}

extension EnvironmentValues {
    var appCoordinator: AppCoordinator {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}

// MARK: - View Extension for Convenience

extension View {
    func withAppCoordinator(_ coordinator: AppCoordinator) -> some View {
        self.environment(\.appCoordinator, coordinator)
    }
}
