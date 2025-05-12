//
//
// SwiftAIChatGPT
// ChatCoordinator.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import Foundation
import SwiftUI
import SwiftData

@Observable
class ChatCoordinator {
    var viewModel: ChatViewModel?
    var actionHandler = MessageActionHandler()
    
    private let modelContext: ModelContext
    private let appCoordinator: AppCoordinator
    
    init(modelContext: ModelContext, appCoordinator: AppCoordinator) {
        self.modelContext = modelContext
        self.appCoordinator = appCoordinator
    }
    
    func initializeViewModel(for conversation: Conversation) {
        // Clean up previous resources if needed
        resetForNewConversation()
        
        // Create new view model
        let vm = ChatViewModel(
            conversation: conversation,
            modelContext: modelContext,
            networkMonitor: appCoordinator.networkMonitor,
            networkService: appCoordinator.networkService,
            errorHandler: { [weak self] error in
                self?.appCoordinator.handleError(error)
            }
        )
        viewModel = vm
    }
    
    func resetForNewConversation() {
        actionHandler.stopSpeaking()
        viewModel = nil
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
