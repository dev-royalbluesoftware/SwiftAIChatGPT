//
//
// SwiftAIChatGPT
// VoiceChatViewModel.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI
import AVFoundation
import Speech

@Observable
class VoiceChatViewModel {
    var isRecording = false
    var isProcessing = false
    var transcribedText = ""
    var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()
    
    // Modern approach for iOS 17+ using async/await
    @MainActor
    func requestMicrophonePermission() async -> Bool {
        // For iOS 17+, use AVAudioApplication
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            // Fallback for iOS 16 and earlier
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // Check current permission status - using enum for cross-version compatibility
    func checkMicrophonePermission() -> MicrophonePermissionStatus {
        if #available(iOS 17.0, *) {
            // Convert AVAudioApplication permission to our enum
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                return .undetermined
            @unknown default:
                return .undetermined
            }
        } else {
            // Convert AVAudioSession permission to our enum
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                return .undetermined
            @unknown default:
                return .undetermined
            }
        }
    }
    
    func startVoiceChat() async {
        let permissionStatus = checkMicrophonePermission()
        
        switch permissionStatus {
        case .granted:
            await startRecording()
        case .denied:
            errorMessage = "Microphone access is denied. Please enable it in Settings."
        case .undetermined:
            let granted = await requestMicrophonePermission()
            if granted {
                await startRecording()
            } else {
                errorMessage = "Microphone access is required for voice chat."
            }
        }
    }
    
    private func startRecording() async {
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Initialize audio engine
            audioEngine = AVAudioEngine()
            
            // Setup audio input
            guard let inputNode = audioEngine?.inputNode else {
                throw VoiceChatError.audioInputUnavailable
            }
            
            // Start recording
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            audioEngine?.prepare()
            try audioEngine?.start()
            
            isRecording = true
            
            // Setup speech recognition (optional)
            setupSpeechRecognition()
            
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            isRecording = false
        }
    }
    
    private func setupSpeechRecognition() {
        // Check speech recognition availability
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                self?.transcribedText = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                self?.stopRecording()
            }
        }
    }
    
    func stopVoiceChat() {
        stopRecording()
    }
    
    private func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
    }
    
    deinit {
        stopRecording()
    }
}

// Custom error enum for voice chat
enum VoiceChatError: Error {
    case audioInputUnavailable
    case speechRecognitionUnavailable
    case permissionDenied
    
    var localizedDescription: String {
        switch self {
        case .audioInputUnavailable:
            return "Audio input is not available"
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available"
        case .permissionDenied:
            return "Microphone permission is denied"
        }
    }
}

// Custom enum to handle permission status across iOS versions
enum MicrophonePermissionStatus {
    case granted
    case denied
    case undetermined
}
