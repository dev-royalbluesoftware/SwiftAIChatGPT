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
    static func tick() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    static func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
    }
    
    static func success() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}
