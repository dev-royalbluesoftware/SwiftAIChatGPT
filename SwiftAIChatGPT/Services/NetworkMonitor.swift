//
//
// SwiftAIChatGPT
// NetworkMonitor.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import Network
import SwiftUI

@Observable
class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected = true
    var connectionType = NWInterface.InterfaceType.other
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type ?? .other
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// Error types for better error handling
enum ChatError: LocalizedError {
    case networkUnavailable
    case apiError(String)
    case invalidResponse
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .apiError(let message):
            return "API Error: \(message)"
        case .invalidResponse:
            return "Invalid response from server."
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
}
