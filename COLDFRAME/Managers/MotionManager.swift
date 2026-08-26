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
        let frames = CMMotionManager.availableAttitudeReferenceFrames()
        return frames.contains(.xTrueNorthZVertical) || frames.contains(.xMagneticNorthZVertical)
    }

    @ObservationIgnored private var isInitialized: Bool = false
    private let smoothingFactor: Double = 0.35 // Lissage réactif et fluide

    func startTracking() {
        guard !isTracking else { return }
        guard motionManager.isDeviceMotionAvailable else { return }

        isInitialized = false
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz

        let availableFrames = CMMotionManager.availableAttitudeReferenceFrames()
        let frame: CMAttitudeReferenceFrame
        if availableFrames.contains(.xTrueNorthZVertical) {
            frame = .xTrueNorthZVertical
        } else if availableFrames.contains(.xMagneticNorthZVertical) {
            frame = .xMagneticNorthZVertical
        } else if availableFrames.contains(.xArbitraryCorrectedZVertical) {
            frame = .xArbitraryCorrectedZVertical
        } else {
            frame = .xArbitraryZVertical
        }

        motionManager.startDeviceMotionUpdates(using: frame, to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }

            let matrix = motion.attitude.rotationMatrix

            // Dans CoreMotion avec repère Z-Vertical :
            // Axe optique de la caméra arrière = vecteur (0, 0, -1) dans le repère de l'iPhone
            // Dans le repère terrestre (+X = Nord, +Y = Ouest, +Z = Zénith) :
            // northComp = -m13, eastComp = +m23 (car Est = -Ouest), upComp = -m33
            let northComp = -matrix.m13
            let eastComp = matrix.m23
            let upComp = -matrix.m33

            // 1. Élévation optique (Pitch)
            let clampedUp = max(-1.0, min(1.0, upComp))
            let rawPitch = asin(clampedUp) * 180.0 / .pi

            // 2. Cap boussole réel (Yaw 360°)
            let yawRad = atan2(eastComp, northComp)
            var rawYaw = yawRad * 180.0 / .pi
            if rawYaw < 0 { rawYaw += 360.0 }
            rawYaw = rawYaw.truncatingRemainder(dividingBy: 360.0)

            // 3. Filtrage passe-bas continu
            if !self.isInitialized {
                self.pitchDegrees = rawPitch
                self.yawDegrees = rawYaw
                self.isInitialized = true
            } else {
                self.pitchDegrees += (rawPitch - self.pitchDegrees) * self.smoothingFactor

                var diffYaw = rawYaw - self.yawDegrees
                while diffYaw > 180.0 { diffYaw -= 360.0 }
                while diffYaw < -180.0 { diffYaw += 360.0 }
                var smoothedYaw = self.yawDegrees + diffYaw * self.smoothingFactor
                if smoothedYaw < 0 { smoothedYaw += 360.0 }
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
