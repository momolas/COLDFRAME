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

    var pitchDegrees: Double = 0.0
    var rollDegrees: Double = 0.0
    var yawDegrees: Double = 0.0 // 0 = Nord, 90 = Est, 180 = Sud, 270 = Ouest
    var isTracking: Bool = false

    var isAvailable: Bool {
        CMMotionManager.availableAttitudeReferenceFrames().contains(.xTrueNorthZVertical)
    }

    func startTracking() {
        guard !isTracking else { return }
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz pour une fluidité AR parfaite

        let frame: CMAttitudeReferenceFrame = isAvailable ? .xTrueNorthZVertical : .xMagneticNorthZVertical

        motionManager.startDeviceMotionUpdates(using: frame, to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }

            // En mode paysage (Landscape Left / Right) :
            // pitch = inclinaison haut/bas de la caméra
            // roll = inclinaison latérale
            // yaw = azimut pointé par la caméra
            let attitude = motion.attitude

            // Conversion en degrés
            let pitch = attitude.pitch * 180.0 / .pi
            let roll = attitude.roll * 180.0 / .pi
            
            // Yaw normalisé en cap 0..360°
            let yawRad = attitude.yaw
            let yawDeg = (-yawRad * 180.0 / .pi + 360.0).truncatingRemainder(dividingBy: 360.0)

            self.pitchDegrees = pitch
            self.rollDegrees = roll
            self.yawDegrees = yawDeg
        }

        isTracking = true
    }

    func stopTracking() {
        guard isTracking else { return }
        motionManager.stopDeviceMotionUpdates()
        isTracking = false
    }
}
