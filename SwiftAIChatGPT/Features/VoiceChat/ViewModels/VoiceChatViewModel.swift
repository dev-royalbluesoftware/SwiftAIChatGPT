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
class VoiceChatViewModel: NSObject {
    var isRecording = false
    var isProcessing = false
    var transcribedText = ""
    var aiResponse = ""
    var isAISpeaking = false
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioRecorder: AVAudioRecorder?
    
    // Audio level monitoring
    var userAudioLevel: Float = 0.0
    var aiAudioLevel: Float = 0.0
    private var levelTimer: Timer?
    
    // Error handling
    private let errorHandler: (AppError) -> Void
    
    init(errorHandler: @escaping (AppError) -> Void) {
        self.errorHandler = errorHandler
        super.init()
        speechSynthesizer.delegate = self
    }
    
    // Modern approach for iOS 17+ using async/await
    @MainActor
    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    @MainActor
    func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func checkMicrophonePermission() -> MicrophonePermissionStatus {
        if #available(iOS 17.0, *) {
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
        let micPermission = checkMicrophonePermission()
        
        switch micPermission {
        case .granted:
            let speechGranted = await requestSpeechPermission()
            if speechGranted {
                await startRecording()
            } else {
                errorHandler(.permissionDenied(.speechRecognition))
            }
        case .denied:
            errorHandler(.permissionDenied(.microphone))
        case .undetermined:
            let granted = await requestMicrophonePermission()
            if granted {
                let speechGranted = await requestSpeechPermission()
                if speechGranted {
                    await startRecording()
                } else {
                    errorHandler(.permissionDenied(.speechRecognition))
                }
            } else {
                errorHandler(.permissionDenied(.microphone))
            }
        }
    }
    
    private func startRecording() async {
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Initialize audio engine
            audioEngine = AVAudioEngine()
            
            // Setup audio input
            guard let inputNode = audioEngine?.inputNode else {
                throw VoiceChatError.audioInputUnavailable
            }
            
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.taskHint = .dictation
            
            // Start recognition task
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                    
                    // If the user pauses speaking, process their input
                    if result.isFinal {
                        self.processUserInput(result.bestTranscription.formattedString)
                    }
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.handleRecognitionError(error)
                    }
                }
            }
            
            // Start recording and monitoring audio levels
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                
                // Calculate audio level
                let level = self?.calculateAudioLevel(from: buffer) ?? 0
                DispatchQueue.main.async {
                    self?.userAudioLevel = level
                }
            }
            
            audioEngine?.prepare()
            try audioEngine?.start()
            
            isRecording = true
            HapticService.tick()
            
        } catch {
            handleStartRecordingError(error)
        }
    }
    
    private func handleStartRecordingError(_ error: Error) {
        if let voiceChatError = error as? VoiceChatError {
            switch voiceChatError {
            case .audioInputUnavailable:
                errorHandler(.recordingFailed("Audio input is not available"))
            case .speechRecognitionUnavailable:
                errorHandler(.speechRecognitionFailed("Speech recognition is not available"))
            case .permissionDenied:
                errorHandler(.permissionDenied(.microphone))
            }
        } else {
            errorHandler(.recordingFailed(error.localizedDescription))
        }
        isRecording = false
    }
    
    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        switch nsError.domain {
        case "kLSRErrorDomain":
            // Speech recognition specific errors
            switch nsError.code {
            case 201: // No speech detected
                errorHandler(.speechRecognitionFailed("No speech detected. Please speak clearly."))
            case 203: // Audio recording error
                errorHandler(.recordingFailed("Audio recording error"))
            default:
                errorHandler(.speechRecognitionFailed("Recognition failed"))
            }
        default:
            errorHandler(.speechRecognitionFailed(error.localizedDescription))
        }
        stopRecording()
    }
    
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        var total: Float = 0
        for channel in 0..<channelCount {
            for frame in 0..<frameLength {
                let sample = channelData[channel][frame]
                total += sample * sample
            }
        }
        
        let rms = sqrt(total / Float(channelCount * frameLength))
        let avgPower = 20 * log10(rms)
        
        // Normalize to 0-1 range
        let minDb: Float = -50
        let maxDb: Float = 0
        let normalizedPower = (avgPower - minDb) / (maxDb - minDb)
        
        return max(0, min(1, normalizedPower))
    }
    
    private func processUserInput(_ text: String) {
        guard !text.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isProcessing = true
            self.stopRecording()
        }
        
        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.generateAIResponse(for: text)
        }
    }
    
    private func generateAIResponse(for input: String) {
        // Mock AI responses
        let responses = [
            "I understand you said: \(input). That's an interesting point!",
            "Let me help you with that. \(input) is something I can definitely assist with.",
            "Based on what you said about \(input), here's what I think...",
            "That's fascinating! Tell me more about \(input)."
        ]
        
        let response = responses.randomElement() ?? "I'm here to help!"
        
        DispatchQueue.main.async {
            self.aiResponse = response
            self.isProcessing = false
            self.speakResponse(response)
        }
    }
    
    private func speakResponse(_ text: String) {
        isAISpeaking = true
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9
        
        // Simulate audio level changes during speech
        startAudioLevelSimulation()
        
        speechSynthesizer.speak(utterance)
        HapticService.tick()
    }
    
    private func startAudioLevelSimulation() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, self.isAISpeaking else { return }
            
            // Simulate varying audio levels
            self.aiAudioLevel = Float.random(in: 0.3...0.8)
        }
    }
    
    func stopVoiceChat() {
        stopRecording()
        speechSynthesizer.stopSpeaking(at: .immediate)
        levelTimer?.invalidate()
        levelTimer = nil
        isAISpeaking = false
        aiAudioLevel = 0
        userAudioLevel = 0
    }
    
    private func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
        
        isRecording = false
        userAudioLevel = 0
    }
    
    deinit {
        stopVoiceChat()
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceChatViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isAISpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isAISpeaking = false
            self.aiAudioLevel = 0
            self.levelTimer?.invalidate()
            self.levelTimer = nil
            
            // Resume recording after AI finishes speaking
            Task {
                await self.startRecording()
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isAISpeaking = false
            self.aiAudioLevel = 0
            self.levelTimer?.invalidate()
            self.levelTimer = nil
        }
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
            return "Permission is denied"
        }
    }
}

// Custom enum to handle permission status across iOS versions
enum MicrophonePermissionStatus {
    case granted
    case denied
    case undetermined
}
