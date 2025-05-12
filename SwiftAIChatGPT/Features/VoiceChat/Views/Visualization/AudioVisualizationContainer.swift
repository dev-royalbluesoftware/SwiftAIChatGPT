//
//
// SwiftAIChatGPT
// AudioVisualizationContainer.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI
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
        YarnBallVisualization(
            isRecording: $isRecording,
            audioLevel: $audioLevel,
            state: $state
        )
        .frame(maxWidth: .infinity) // Ensure visualization spans the full width of the container
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
