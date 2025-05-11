//
//
// SwiftAIChatGPT
// YarnBallVisualizationView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI

struct YarnBallVisualization: View {
    @Binding var isRecording: Bool
    @Binding var audioLevel: Float
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Ensure audioLevel is safe
                let safeAudioLevel = audioLevel.isFinite ? audioLevel : 0
                let animationSpeed = isRecording ? 1.5 + Double(safeAudioLevel) : 1.0
                
                // Draw 3-4 strands that wrap around a sphere
                for i in 0..<4 {
                    drawStrand(
                        context: context,
                        center: center,
                        time: time * animationSpeed,
                        strandIndex: i,
                        totalStrands: 4,
                        isRecording: isRecording,
                        audioLevel: safeAudioLevel
                    )
                }
            }
        }
        .frame(width: 200, height: 200)
    }
    
    private func drawStrand(
        context: GraphicsContext,
        center: CGPoint,
        time: Double,
        strandIndex: Int,
        totalStrands: Int,
        isRecording: Bool,
        audioLevel: Float
    ) {
        let baseRadius: CGFloat = 70
        let safeAudioLevel = CGFloat(audioLevel.isFinite ? audioLevel : 0)
        let radius = baseRadius + safeAudioLevel * 20 // Pulse based on audio
        let strandOffset = Double(strandIndex) * 2 * .pi / Double(totalStrands)
        
        // Create path for the strand
        var path = Path()
        var firstPoint = true
        
        // Draw strand that wraps around sphere
        for t in stride(from: 0, to: 2 * .pi, by: 0.05) {
            // Parametric equations for a curve on a sphere
            let u = t + time * 0.5 + strandOffset
            let v = sin(t * 3 + time * 0.3) * 0.5 + 0.5
            
            // Add audio-based distortion
            let audioDistortion = isRecording ? sin(t * 10 + time * 5) * safeAudioLevel * 10 : 0
            
            // Convert to spherical coordinates
            let theta = u
            let phi = v * .pi
            
            // Convert to Cartesian coordinates
            let x = (radius + audioDistortion) * sin(phi) * cos(theta)
            let y = (radius + audioDistortion) * sin(phi) * sin(theta)
            let z = radius * cos(phi)
            
            // Apply rotation
            let rotatedX = x * cos(time * 0.2) - z * sin(time * 0.2)
            let rotatedZ = x * sin(time * 0.2) + z * cos(time * 0.2)
            
            // Project to 2D with perspective
            let perspective = 300 / (300 + rotatedZ)
            let screenX = center.x + rotatedX * perspective
            let screenY = center.y + y * perspective
            
            // Ensure coordinates are finite
            guard screenX.isFinite && screenY.isFinite else { continue }
            
            if firstPoint {
                path.move(to: CGPoint(x: screenX, y: screenY))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: screenX, y: screenY))
            }
        }
        
        // Draw the strand with appropriate styling
        let lineWidth = isRecording ? 3 + safeAudioLevel * 2 : 2
        let opacity = isRecording ? 0.9 : 0.6
        
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    strandColor(for: strandIndex).opacity(opacity),
                    strandColor(for: strandIndex).opacity(opacity * 0.7)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 200, y: 200)
            ),
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
    
    private func strandColor(for index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .purple
        case 2: return .pink
        case 3: return .cyan
        default: return .white
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 40) {
            Text("Enhanced Yarn Ball")
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                VStack {
                    YarnBallVisualization(isRecording: .constant(false), audioLevel: .constant(0))
                    Text("Idle")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                VStack {
                    YarnBallVisualization(isRecording: .constant(true), audioLevel: .constant(0.5))
                    Text("Recording")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
        }
    }
}
