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
    private var audioTimer: Timer?
    
    func updateState(isRecording: Bool) {
        withAnimation {
            state = isRecording ? .listening : .idle
        }
    }
    
    func setResponding() {
        state = .responding
        simulateAudioLevel()
    }
    
    private func simulateAudioLevel() {
        audioTimer?.invalidate()
        audioTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.state == .responding {
                self.audioLevel = Float.random(in: 0.3...0.8)
            } else {
                timer.invalidate()
                self.audioLevel = 0.0
            }
        }
    }
    
    func stopSimulation() {
        audioTimer?.invalidate()
        audioTimer = nil
        audioLevel = 0.0
    }
    
    deinit {
        stopSimulation()
    }
}
