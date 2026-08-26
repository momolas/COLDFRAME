//
//  MotionManager.swift
//  COLDFRAME
//

import Foundation
import CoreMotion
import Observation

@MainActor
@Observable
final class MotionManager {
    private let motionManager = CMMotionManager()

    var pitchDegrees: Double = 0.0 // Élévation verticale de l'axe optique caméra (-90° à +90°)
    var isTracking: Bool = false

    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    @ObservationIgnored private var isInitialized: Bool = false
    private let smoothingFactor: Double = 0.35 // Lissage réactif et fluide

    func startTracking() {
        guard !isTracking else { return }
        guard motionManager.isDeviceMotionAvailable else { return }

        isInitialized = false
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }

            let matrix = motion.attitude.rotationMatrix

            // Élévation optique (Pitch) : angle avec le plan horizontal (-90° à +90°)
            let clampedUp = max(-1.0, min(1.0, -matrix.m33))
            let rawPitch = asin(clampedUp) * 180.0 / .pi

            if !self.isInitialized {
                self.pitchDegrees = rawPitch
                self.isInitialized = true
            } else {
                self.pitchDegrees += (rawPitch - self.pitchDegrees) * self.smoothingFactor
            }
        }

        isTracking = true
    }

    func stopTracking() {
        guard isTracking else { return }
        motionManager.stopDeviceMotionUpdates()
        isTracking = false
    }
}
