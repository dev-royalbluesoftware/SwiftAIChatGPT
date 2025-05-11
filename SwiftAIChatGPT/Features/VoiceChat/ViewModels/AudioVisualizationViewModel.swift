//
//
// SwiftAIChatGPT
// AudioVisualizationViewModel.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//


import Foundation
import SwiftUI

@Observable
class AudioVisualizationViewModel {
    var state: AudioVisualizationState = .idle
    var audioLevel: Float = 0.0
    var animationSpeed: Double = 1.0
    
    func updateState(isRecording: Bool, isAISpeaking: Bool = false) {
        withAnimation(.easeInOut(duration: 0.5)) {
            if isAISpeaking {
                state = .responding
            } else if isRecording {
                state = .listening
            } else {
                state = .idle
            }
        }
    }
    
    func updateAudioLevel(_ level: Float) {
        // Ensure the level is a valid number and within bounds
        let safeLevel = level.isFinite ? max(0, min(1, level)) : 0
        audioLevel = safeLevel
        
        // Adjust animation speed based on audio level
        if state == .listening {
            animationSpeed = 1.0 + Double(safeLevel) * 0.5
        }
    }
    
    func reset() {
        state = .idle
        audioLevel = 0.0
        animationSpeed = 1.0
    }
}
