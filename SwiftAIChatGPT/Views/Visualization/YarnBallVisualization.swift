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
    @State private var rotation: Double = 0
    @State private var animationSpeed: Double = 1.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Draw 3-4 strands that wrap around a sphere
                for i in 0..<4 {
                    drawStrand(
                        context: context,
                        center: center,
                        time: time * animationSpeed,
                        strandIndex: i,
                        totalStrands: 4,
                        isRecording: isRecording
                    )
                }
            }
        }
        .frame(width: 200, height: 200)
        .onChange(of: isRecording) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animationSpeed = newValue ? 1.5 : 1.0
            }
        }
    }
    
    private func drawStrand(
        context: GraphicsContext,
        center: CGPoint,
        time: Double,
        strandIndex: Int,
        totalStrands: Int,
        isRecording: Bool
    ) {
        let radius: CGFloat = 70
        let strandOffset = Double(strandIndex) * 2 * .pi / Double(totalStrands)
        
        // Create path for the strand
        var path = Path()
        var firstPoint = true
        
        // Draw strand that wraps around sphere
        for t in stride(from: 0, to: 2 * .pi, by: 0.05) {
            // Parametric equations for a curve on a sphere
            let u = t + time * 0.5 + strandOffset
            let v = sin(t * 3 + time * 0.3) * 0.5 + 0.5
            
            // Convert to spherical coordinates
            let theta = u
            let phi = v * .pi
            
            // Convert to Cartesian coordinates
            let x = radius * sin(phi) * cos(theta)
            let y = radius * sin(phi) * sin(theta)
            let z = radius * cos(phi)
            
            // Apply rotation
            let rotatedX = x * cos(time * 0.2) - z * sin(time * 0.2)
            let rotatedZ = x * sin(time * 0.2) + z * cos(time * 0.2)
            
            // Project to 2D with perspective
            let perspective = 300 / (300 + rotatedZ)
            let screenX = center.x + rotatedX * perspective
            let screenY = center.y + y * perspective
            
            if firstPoint {
                path.move(to: CGPoint(x: screenX, y: screenY))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: screenX, y: screenY))
            }
        }
        
        // Draw the strand with appropriate styling
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    strandColor(for: strandIndex).opacity(0.9),
                    strandColor(for: strandIndex).opacity(0.6)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 200, y: 200)
            ),
            style: StrokeStyle(
                lineWidth: isRecording ? 3 : 2,
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
            Text("3D Yarn Ball")
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                VStack {
                    YarnBallVisualization(isRecording: .constant(false))
                    Text("Idle")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                VStack {
                    YarnBallVisualization(isRecording: .constant(true))
                    Text("Recording")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
        }
    }
}
