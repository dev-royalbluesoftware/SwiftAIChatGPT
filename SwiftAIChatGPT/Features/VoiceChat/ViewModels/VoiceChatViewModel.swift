//
//
// SwiftAIChatGPT
// VoiceChatViewModel.swift
//
// Created by rbs-dev
// Copyright Royal Blue Software
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
    var permissionDenied = false
    var deniedPermissionType: AppError.PermissionType?
    var isBeingDismissed = false
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // Audio level monitoring
    var userAudioLevel: Float = 0.0
    var aiAudioLevel: Float = 0.0
    private var levelTimer: Timer?
    
    // Error handling
    private let errorHandler: (AppError) -> Void
    
    // Track if we're intentionally stopping
    private var isIntentionallyStopping = false
    
    // Track if we've received any transcription
    private var hasReceivedTranscription = false
    
    // Queue for audio operations
    private let audioQueue = DispatchQueue(label: "com.app.audioQueue", qos: .userInitiated)
    private var audioLevelThrottler: Date = Date()
    private let audioLevelUpdateInterval: TimeInterval = 0.1  // Update at 10Hz instead of 32Hz+
    
    // Add flag to prevent automatic restart on error
    private var hasEncounteredError = false
    
    // Add retry tracking
    private var retryCount = 0
    private let maxRetries = 3
    
    init(errorHandler: @escaping (AppError) -> Void) {
        self.errorHandler = errorHandler
        super.init()
        speechSynthesizer.delegate = self
        
        // Configure audio session on init
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        } catch {
            print("Failed to configure audio session: \(error)")
        }
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
        // Reset flags and clear previous content
        await MainActor.run {
            isIntentionallyStopping = false
            hasReceivedTranscription = false
            hasEncounteredError = false
            retryCount = 0
            transcribedText = ""
            aiResponse = ""  // Clear AI response from previous session
            permissionDenied = false
            deniedPermissionType = nil
        }
        
        let micPermission = checkMicrophonePermission()
        
        switch micPermission {
        case .granted:
            let speechGranted = await requestSpeechPermission()
            if speechGranted {
                await startRecordingWithRetry()
            } else {
                await MainActor.run {
                    permissionDenied = true
                    deniedPermissionType = .speechRecognition
                }
                errorHandler(.permissionDenied(.speechRecognition))
            }
        case .denied:
            await MainActor.run {
                permissionDenied = true
                deniedPermissionType = .microphone
            }
            errorHandler(.permissionDenied(.microphone))
        case .undetermined:
            let granted = await requestMicrophonePermission()
            if granted {
                let speechGranted = await requestSpeechPermission()
                if speechGranted {
                    await startRecordingWithRetry()
                } else {
                    await MainActor.run {
                        permissionDenied = true
                        deniedPermissionType = .speechRecognition
                    }
                    errorHandler(.permissionDenied(.speechRecognition))
                }
            } else {
                await MainActor.run {
                    permissionDenied = true
                    deniedPermissionType = .microphone
                }
                errorHandler(.permissionDenied(.microphone))
            }
        }
    }
    
    private func startRecordingWithRetry() async {
        if retryCount >= maxRetries {
            await MainActor.run {
                errorHandler(.speechRecognitionFailed("Speech recognition failed after multiple attempts"))
            }
            return
        }
        
        await startRecording()
    }
    
    private func startRecording() async {
        // Don't start if we're already recording or have encountered errors
        guard !isRecording && !hasEncounteredError else { return }
        
        await MainActor.run {
            isRecording = true
            // Clear previous responses when starting new recording
            aiResponse = ""
            transcribedText = ""
            hasReceivedTranscription = false
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Activate audio session
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                // Initialize audio engine
                self.audioEngine = AVAudioEngine()
                guard let audioEngine = self.audioEngine else { throw VoiceChatError.audioInputUnavailable }
                
                // Setup audio input
                let inputNode = audioEngine.inputNode
                
                // Create recognition request
                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = self.recognitionRequest else {
                    throw VoiceChatError.speechRecognitionUnavailable
                }
                
                recognitionRequest.shouldReportPartialResults = true
                recognitionRequest.taskHint = .dictation
                recognitionRequest.requiresOnDeviceRecognition = false  // Allow server-based recognition
                
                // Declare silence timer for handling input processing
                var silenceTimer: Timer?
                
                // Check if recognizer is available
                guard let speechRecognizer = self.speechRecognizer, speechRecognizer.isAvailable else {
                    throw VoiceChatError.speechRecognitionUnavailable
                }
                
                // Configure recording format
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                // Start recognition task
                self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    // Check if we should still be processing
                    if self.isIntentionallyStopping || self.hasEncounteredError || self.isBeingDismissed {
                        return
                    }
                    
                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        
                        DispatchQueue.main.async {
                            // Again check if we're being dismissed before updates
                            if self.isBeingDismissed { return }
                            
                            // Only update if transcription actually changed
                            if self.transcribedText != transcription {
                                self.transcribedText = transcription
                                self.hasReceivedTranscription = true
                            }
                            
                            // Reset silence timer
                            silenceTimer?.invalidate()
                            
                            // Only set timer if we have actual transcription
                            if !transcription.isEmpty {
                                silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                    // Process if we have transcription and user stops talking
                                    if self.hasReceivedTranscription && !self.transcribedText.isEmpty && !self.isProcessing && !self.isBeingDismissed {
                                        self.processUserInput(self.transcribedText)
                                    }
                                }
                            }
                        }
                        
                        // If the result is final, process immediately
                        if result.isFinal {
                            silenceTimer?.invalidate()
                            self.processUserInput(result.bestTranscription.formattedString)
                        }
                    }
                    
                    if let error = error {
                        silenceTimer?.invalidate()
                        // Only handle error if we're not intentionally stopping
                        if !self.isIntentionallyStopping {
                            self.handleRecognitionError(error)
                        }
                    }
                }
                
                // Install tap on input node with proper weak reference handling
                inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
                    guard let self = self else { return }
                    
                    // Check dismissal state before doing anything
                    if self.isBeingDismissed { return }
                    
                    // Capture reference to request to avoid potential race condition
                    guard let request = self.recognitionRequest else { return }
                    
                    // Append buffer to captured request reference
                    request.append(buffer)
                    
                    // Throttle audio level updates
                    let now = Date()
                    if now.timeIntervalSince(self.audioLevelThrottler) >= self.audioLevelUpdateInterval {
                        self.audioLevelThrottler = now
                        
                        // Re-check dismissal state
                        if self.isBeingDismissed { return }
                        
                        self.audioQueue.async { [weak self] in
                            guard let self = self, !self.isBeingDismissed else { return }
                            
                            let audioLevel = self.calculateAudioLevel(from: buffer)
                            
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self, !self.isBeingDismissed else { return }
                                self.userAudioLevel = audioLevel
                            }
                        }
                    }
                }
                
                // Prepare and start the engine
                audioEngine.prepare()
                try audioEngine.start()
                
            } catch {
                DispatchQueue.main.async {
                    self.handleStartRecordingError(error)
                }
            }
        }
    }
    
    private func handleStartRecordingError(_ error: Error) {
        isRecording = false
        
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
    }
    
    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        
        // Don't show error if we're intentionally stopping
        if isIntentionallyStopping {
            return
        }
        
        // Set error flag to prevent automatic restart
        hasEncounteredError = true
        
        DispatchQueue.main.async {
            switch nsError.domain {
            case "kAFAssistantErrorDomain":
                switch nsError.code {
                case 1101: // Service error - often means speech recognition is temporarily unavailable
                    print("Speech recognition service temporarily unavailable")
                    // Don't retry automatically for 1101 errors
                    self.errorHandler(.speechRecognitionFailed("Speech recognition service is temporarily unavailable. Please try again."))
                    self.stopRecording()
                    return
                    
                case 209: // Speech recognition unavailable
                    self.errorHandler(.speechRecognitionFailed("Speech recognition is not available"))
                default:
                    self.errorHandler(.speechRecognitionFailed("Speech service error: \(nsError.code)"))
                }
                
            case "kLSRErrorDomain":
                // Speech recognition specific errors
                switch nsError.code {
                case 201: // No speech detected
                    // Be more lenient with "no speech detected" errors
                    if !self.hasReceivedTranscription && !self.transcribedText.isEmpty && !self.isIntentionallyStopping {
                        // Don't show error immediately, just stop recording
                        self.stopRecording()
                    }
                case 203: // Audio recording error
                    self.errorHandler(.recordingFailed("Audio recording error"))
                case 1110: // Connection issue
                    print("Speech recognition connection issue")
                    // Don't retry automatically
                    self.errorHandler(.speechRecognitionFailed("Connection issue. Please try again."))
                default:
                    if !self.isIntentionallyStopping {
                        self.errorHandler(.speechRecognitionFailed("Recognition error: \(nsError.code)"))
                    }
                }
                
            default:
                if !self.isIntentionallyStopping {
                    self.errorHandler(.speechRecognitionFailed(error.localizedDescription))
                }
            }
            
            // Always stop recording on error
            self.stopRecording()
        }
    }
    
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        guard channelCount > 0 && frameLength > 0 else { return 0 }
        
        var total: Float = 0
        for channel in 0..<channelCount {
            for frame in 0..<frameLength {
                let sample = channelData[channel][frame]
                total += sample * sample
            }
        }
        
        let rms = sqrt(total / Float(channelCount * frameLength))
        
        // Guard against log of zero or negative values
        guard rms > 0 else { return 0 }
        
        let avgPower = 20 * log10(rms)
        
        // Ensure avgPower is finite
        guard avgPower.isFinite else { return 0 }
        
        // Normalize to 0-1 range
        let minDb: Float = -50
        let maxDb: Float = 0
        let normalizedPower = (avgPower - minDb) / (maxDb - minDb)
        
        // Ensure the final value is finite and within bounds
        let finalValue = max(0, min(1, normalizedPower))
        return finalValue.isFinite ? finalValue : 0
    }
    
    private func processUserInput(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Prevent duplicate processing
        guard !isProcessing else { return }
        
        DispatchQueue.main.async {
            self.isProcessing = true
            self.isIntentionallyStopping = true  // Mark as intentionally stopping
            self.hasEncounteredError = true  // Prevent auto-restart
            self.stopRecording()
            
            // Only show the final transcription
            self.transcribedText = text
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
            self.hasEncounteredError = true  // Prevent any automatic recording after response
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
        // Removed haptic feedback to reduce load
    }
    
    private func startAudioLevelSimulation() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isAISpeaking else {
                self?.levelTimer?.invalidate()
                self?.levelTimer = nil
                return
            }
            
            // Simulate varying audio levels with less frequent updates
            self.aiAudioLevel = Float.random(in: 0.3...0.8)
        }
    }
    
    func stopVoiceChat() {
        isIntentionallyStopping = true
        hasEncounteredError = true  // Prevent automatic restart
        stopRecording()
        speechSynthesizer.stopSpeaking(at: .immediate)
        levelTimer?.invalidate()
        levelTimer = nil
        isAISpeaking = false
        aiAudioLevel = 0
        userAudioLevel = 0
        
        // Clear permission error state
        permissionDenied = false
        deniedPermissionType = nil
        
        // Ensure all values are reset to prevent NaN issues
        isRecording = false
        isProcessing = false
    }
    
    private func stopRecording() {
        DispatchQueue.main.async {
            self.isIntentionallyStopping = true  // Mark as intentionally stopping
            self.isRecording = false
            self.userAudioLevel = 0
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop audio engine first
            self.audioEngine?.stop()
            
            // Wait a bit before removing tap to avoid crashes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.audioEngine?.inputNode.removeTap(onBus: 0)
            }
            
            // End recognition
            self.recognitionRequest?.endAudio()
            
            // Always cancel the task to prevent lingering errors
            self.recognitionTask?.cancel()
            
            // Clean up after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.audioEngine = nil
                
                // Deactivate audio session
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                
                // Only process pending text if we're stopping due to user input
                if self.hasReceivedTranscription && !self.transcribedText.isEmpty && self.isIntentionallyStopping && !self.hasEncounteredError {
                    self.processUserInput(self.transcribedText)
                }
            }
        }
    }
    
    // MARK: - Safe Dismissal
    
    func prepareForDismissal() {
        // Set the dismissal flag first to prevent async operations
        isBeingDismissed = true
        
        // Set other flags
        isIntentionallyStopping = true
        hasEncounteredError = true
        
        // Reset state variables immediately
        isRecording = false
        isProcessing = false
        isAISpeaking = false
        transcribedText = ""
        aiResponse = ""
        userAudioLevel = 0
        aiAudioLevel = 0
        permissionDenied = false
        deniedPermissionType = nil
        
        // Important: Stop recognition task first
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Then end recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Stop speech synthesis
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.delegate = nil
        
        // Clean up audio engine
        if let inputNode = audioEngine?.inputNode {
            inputNode.removeTap(onBus: 0)
        }
        audioEngine?.stop()
        audioEngine = nil
        
        // Clean up timers
        levelTimer?.invalidate()
        levelTimer = nil
        
        // Finally deactivate audio session
        DispatchQueue.main.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    deinit {
        // Set dismissal flag first
        isBeingDismissed = true
        
        // Cancel recognition task first
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Then clean up request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Stop speech synthesis
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.delegate = nil
        
        // Clean up audio engine
        if let inputNode = audioEngine?.inputNode {
            inputNode.removeTap(onBus: 0)
        }
        audioEngine?.stop()
        audioEngine = nil
        
        // Clean up timers
        levelTimer?.invalidate()
        levelTimer = nil
        
        // Finally deactivate audio session
        DispatchQueue.main.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func retryAfterPermissionError() {
        permissionDenied = false
        deniedPermissionType = nil
        
        // Reset these flags to allow a fresh start
        isIntentionallyStopping = false
        hasEncounteredError = false
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
            
            // Set states to prevent any automatic recording
            self.isIntentionallyStopping = true
            self.hasEncounteredError = true
            self.isRecording = false
            
            // Fully reset for next manual interaction
            self.isProcessing = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isAISpeaking = false
            self.aiAudioLevel = 0
            self.levelTimer?.invalidate()
            self.levelTimer = nil
            self.isIntentionallyStopping = false  // Reset flag
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
