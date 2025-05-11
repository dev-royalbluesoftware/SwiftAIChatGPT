//
//
// SwiftAIChatGPT
// AppError.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import Foundation

enum AppError: LocalizedError, Equatable {
    case networkUnavailable
    case permissionDenied(PermissionType)
    case saveFailed(String)
    case messageNotSent(String)
    case conversationNotFound
    case recordingFailed(String)
    case speechRecognitionFailed(String)
    case apiError(String)
    case timeout
    case unknown(String)
    
    enum PermissionType: String {
        case microphone = "Microphone"
        case speechRecognition = "Speech Recognition"
    }
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .permissionDenied(let permission):
            return "\(permission.rawValue) permission is required for this feature."
        case .saveFailed(let details):
            return "Failed to save data: \(details)"
        case .messageNotSent(let reason):
            return "Message could not be sent: \(reason)"
        case .conversationNotFound:
            return "Conversation not found. It may have been deleted."
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .speechRecognitionFailed(let reason):
            return "Speech recognition failed: \(reason)"
        case .apiError(let message):
            return "Server error: \(message)"
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown(let details):
            return "An unexpected error occurred: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .permissionDenied(let permission):
            return "Go to Settings to enable \(permission.rawValue) access."
        case .saveFailed:
            return "Try again or restart the app if the problem persists."
        case .messageNotSent:
            return "Check your connection and try sending again."
        case .conversationNotFound:
            return "Return to the conversation list and select a different conversation."
        case .recordingFailed:
            return "Check your microphone and try again."
        case .speechRecognitionFailed:
            return "Speak clearly and try again."
        case .apiError:
            return "Wait a moment and try again."
        case .timeout:
            return "Check your connection and try again."
        case .unknown:
            return "Try again or contact support if the problem persists."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .messageNotSent, .timeout, .apiError:
            return true
        default:
            return false
        }
    }
    
    var requiresSettings: Bool {
        if case .permissionDenied = self {
            return true
        }
        return false
    }
}
