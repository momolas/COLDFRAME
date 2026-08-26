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
    var rollDegrees: Double = 0.0  // Roulis de l'appareil
    var screenRollDegrees: Double = 0.0 // Angle d'inclinaison 2D de l'écran par rapport à l'horizon (-180° à +180°)
    var yawDegrees: Double = 0.0   // Azimut boussole réel de visée (0° = Nord, 90° = Est, 180° = Sud, 270° = Ouest)
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
