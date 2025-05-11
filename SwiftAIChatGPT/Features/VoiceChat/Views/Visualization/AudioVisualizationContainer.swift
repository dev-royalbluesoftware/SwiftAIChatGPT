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
                YarnBallVisualization(
                    isRecording: $isRecording,
                    audioLevel: $audioLevel
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 1.2))
                ))
            }
            
            if state == .responding {
                EqualizerVisualization(audioLevel: $audioLevel)
                    .transition(.asymmetric(
                        insertion: .slide.combined(with: .opacity),
                        removal: .slide.combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: state)
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
