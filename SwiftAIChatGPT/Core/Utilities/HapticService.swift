//
//
// SwiftAIChatGPT
// HapticService.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import UIKit

struct HapticService {
    private static var lastHapticTime: Date = Date()
    private static let minimumInterval: TimeInterval = 0.1 // Minimum 100ms between haptics
    
    static func tick() {
        // Throttle haptic feedback
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= minimumInterval else { return }
        
        lastHapticTime = now
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()
    }
    
    static func error() {
        // Throttle haptic feedback
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= minimumInterval else { return }
        
        lastHapticTime = now
        
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.error)
    }
    
    static func success() {
        // Throttle haptic feedback
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= minimumInterval else { return }
        
        lastHapticTime = now
        
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)
    }
}
