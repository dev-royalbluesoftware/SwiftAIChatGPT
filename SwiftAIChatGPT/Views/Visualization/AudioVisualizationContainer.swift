//
//
// SwiftAIChatGPT
// AudioVisualizationContainer.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI

enum AudioVisualizationState {
    case idle
    case listening
    case responding
}

struct AudioVisualizationContainer: View {
    @Binding var state: AudioVisualizationState
    @Binding var audioLevel: Float
    @Binding var isRecording: Bool
    
    var body: some View {
        ZStack {
            if state == .idle || state == .listening {
                YarnBallVisualization(isRecording: $isRecording)
                    .transition(.opacity.combined(with: .scale))
            }
            
            if state == .responding {
                EqualizerVisualization(audioLevel: $audioLevel)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity),
                        removal: .scale(scale: 10).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: state)
    }
}

#Preview {
    AudioVisualizationContainer(
        state: .constant(.idle),
        audioLevel: .constant(0.5),
        isRecording: .constant(false)
    )
    .frame(height: 200)
    .padding()
    .background(Color.black)
}
