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

    @ObservationIgnored private var pitchKalman = KalmanAngleFilter(isCircular: false)
    @ObservationIgnored private var lastTimestamp: TimeInterval = 0.0

    func startTracking() {
        guard !isTracking else { return }
        guard motionManager.isDeviceMotionAvailable else { return }

        pitchKalman.reset()
        lastTimestamp = 0.0
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }

            let currentTimestamp = motion.timestamp
            let dt: Double = self.lastTimestamp > 0 ? min(0.1, max(0.001, currentTimestamp - self.lastTimestamp)) : (1.0 / 60.0)
            self.lastTimestamp = currentTimestamp

            let matrix = motion.attitude.rotationMatrix

            // Élévation optique (Pitch) : angle avec le plan horizontal (-90° à +90°)
            let clampedUp = max(-1.0, min(1.0, -matrix.m33))
            let rawPitch = asin(clampedUp) * 180.0 / .pi

            // Vitesse de rotation gyroscopique autour de l'axe X (en degrés/seconde)
            let gyroPitchRate = motion.rotationRate.x * 180.0 / .pi

            // Filtrage de Kalman 60 FPS
            self.pitchDegrees = self.pitchKalman.update(
                measuredAngle: rawPitch,
                gyroRateDegreesPerSec: gyroPitchRate,
                dt: dt
            )
        }

        isTracking = true
    }

    func stopTracking() {
        guard isTracking else { return }
        motionManager.stopDeviceMotionUpdates()
        pitchKalman.reset()
        lastTimestamp = 0.0
        isTracking = false
    }
}
