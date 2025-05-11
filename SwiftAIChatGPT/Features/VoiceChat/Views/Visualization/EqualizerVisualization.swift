//
//
// SwiftAIChatGPT
// EqualizerVisualization.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI

struct EqualizerVisualization: View {
    @Binding var audioLevel: Float
    @State private var bars: [CGFloat] = Array(repeating: 0.1, count: 40)
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<bars.count, id: \.self) { index in
                    EqualizerBar(
                        height: bars[index] * geometry.size.height * 0.7,
                        index: index,
                        totalBars: bars.count,
                        audioLevel: audioLevel
                    )
                }
            }
            .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
                updateBars()
            }
        }
        .frame(height: 100)
    }
    
    private func updateBars() {
        for i in 0..<bars.count {
            let centerIndex = bars.count / 2
            let distance = abs(i - centerIndex)
            let normalizedDistance = CGFloat(distance) / CGFloat(centerIndex)
            
            // Create wave effect based on audio level
            let waveHeight = sin(CGFloat(Date().timeIntervalSince1970) * 3 + CGFloat(i) * 0.3)
            let amplitudeMultiplier = max(0.1, CGFloat(audioLevel) - normalizedDistance * 0.5)
            
            withAnimation(.easeInOut(duration: 0.1)) {
                bars[i] = abs(waveHeight) * amplitudeMultiplier
            }
        }
    }
}

struct EqualizerBar: View {
    let height: CGFloat
    let index: Int
    let totalBars: Int
    let audioLevel: Float
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: max(4, height))
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.black
        EqualizerVisualization(audioLevel: .constant(0.5))
    }
}
