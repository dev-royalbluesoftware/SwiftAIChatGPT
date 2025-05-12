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
    @Binding var state: AudioVisualizationState
    
    // Number of strands for the yarn ball
    private let numberOfStrands = 4
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    // Ensure audioLevel is safe
                    let safeAudioLevel = audioLevel.isFinite ? audioLevel : 0
                    let animationSpeed = isRecording ? 1.5 + Double(safeAudioLevel) : 1.0
                    
                    // Draw visualization based on state
                    if state == .idle || state == .listening {
                        // Yarn ball mode - Draw multiple strands
                        for i in 0..<numberOfStrands {
                            drawStrand(
                                context: context,
                                center: center,
                                size: size,
                                time: time * animationSpeed,
                                strandIndex: i,
                                totalStrands: numberOfStrands,
                                isRecording: isRecording,
                                audioLevel: safeAudioLevel
                            )
                        }
                    } else if state == .responding {
                        // Equalizer mode - Draw a single line that represents all strands merged
                        drawSingleEqualizerLine(
                            context: context,
                            size: size,
                            time: time,
                            audioLevel: safeAudioLevel
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 200) // Allow GeometryReader to expand to full width
    }
}

// Draw strand for yarn ball visualization
private func drawStrand(
    context: GraphicsContext,
    center: CGPoint,
    size: CGSize,
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

// Draw a single equalizer line that represents all strands merged together
private func drawSingleEqualizerLine(
    context: GraphicsContext,
    size: CGSize,
    time: Double,
    audioLevel: Float
) {
    // Ensure audio level is safe for calculations
    let safeAudioLevel = CGFloat(audioLevel.isFinite ? audioLevel : 0)
    
    // The single line will be positioned in the center of the view vertically
    let verticalCenter = size.height / 2
    
    // Pin the line to the edges of the screen
    let startPoint = CGPoint(x: 0, y: verticalCenter)
    let endPoint = CGPoint(x: size.width, y: verticalCenter)
    
    // Create the path for the single equalizer line
    var path = Path()
    path.move(to: startPoint)
    
    // Number of segments to create a smooth curve
    let segments = 60
    
    // Draw the wave
    for i in 1...segments {
        let x = startPoint.x + (endPoint.x - startPoint.x) * CGFloat(i) / CGFloat(segments)
        
        // Calculate the wave amplitude based on position
        // This creates a wave that's more pronounced in the center
        let distanceFromCenter = abs(x - size.width / 2) / (size.width / 2)
        
        // The amplitude is highest in the center and decreases toward the edges (which are pinned)
        let amplitude = size.height * 0.3 * safeAudioLevel * (1.0 - pow(distanceFromCenter, 2))
        
        // Create a wave using sine function with time-based animation
        let frequency = 2.0 + safeAudioLevel * 3.0 // Higher audio level = higher frequency
        let wave = sin(CGFloat(time * 5) + CGFloat(i) * (CGFloat.pi * 2) / CGFloat(segments) * frequency) * amplitude
        
        // Add point to the path with wave offset
        let y = verticalCenter + wave
        path.addLine(to: CGPoint(x: x, y: y))
    }
    
    // Ensure the path ends at the exact end point (pinned to edge)
    path.addLine(to: endPoint)
    
    // Stroke width varies with audio level for more dynamic visualization
    let lineWidth = 4.0 + safeAudioLevel * 4.0
    
    // Create a multicolor gradient effect that combines all the strand colors
    let multiColorGradient = Gradient(colors: [
        .blue.opacity(0.9),
        .purple.opacity(0.9),
        .pink.opacity(0.9),
        .cyan.opacity(0.9)
    ])
    
    // Stroke the path with a gradient to give a sense that all strands merged into one
    context.stroke(
        path,
        with: .linearGradient(
            multiColorGradient,
            startPoint: startPoint,
            endPoint: endPoint
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

#Preview {
    VStack {
        ZStack {
            Color.black
            
            VStack(spacing: 40) {
                Text("Yarn Ball to Equalizer Visualization")
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    VStack {
                        YarnBallVisualization(
                            isRecording: .constant(false),
                            audioLevel: .constant(0),
                            state: .constant(.idle)
                        )
                        .frame(height: 150)
                        Text("Idle")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    
                    VStack {
                        YarnBallVisualization(
                            isRecording: .constant(true),
                            audioLevel: .constant(0.5),
                            state: .constant(.listening)
                        )
                        .frame(height: 150)
                        Text("Recording")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        
        ZStack {
            Color.black
            
            VStack {
                Text("AI Speaking - Equalizer")
                    .foregroundColor(.white)
                    .padding(.top)
                
                YarnBallVisualization(
                    isRecording: .constant(false),
                    audioLevel: .constant(0.6),
                    state: .constant(.responding)
                )
                .frame(height: 150)
                .padding(.horizontal, 0) // Ensure no horizontal padding
            }
        }
        .padding(.vertical)
    }
    .previewLayout(.sizeThatFits)
}
