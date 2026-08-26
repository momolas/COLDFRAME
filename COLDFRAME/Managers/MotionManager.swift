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
    var rollDegrees: Double = 0.0  // Roulis de l'écran autour de l'axe optique
    var yawDegrees: Double = 0.0   // Azimut boussole réel de visée (0° = Nord, 90° = Est, 180° = Sud, 270° = Ouest)
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

            let matrix = motion.attitude.rotationMatrix

            // Dans CoreMotion avec xTrueNorthZVertical :
            // Monde : +X = Nord, +Y = Est, +Z = Haut (Zénith)
            // Appareil : La caméra arrière pointe selon le vecteur (0, 0, -1)
            // Vecteur de visée caméra dans l'espace monde :
            let vx = -matrix.m13 // Composante Nord
            let vy = -matrix.m23 // Composante Est
            let vz = -matrix.m33 // Composante Verticale (Zénith)

            // 1. Calcul de l'élévation optique réelle (Pitch) : angle avec le plan horizontal
            let clampedVz = max(-1.0, min(1.0, vz))
            let pitchRad = asin(clampedVz)
            let pitch = pitchRad * 180.0 / .pi

            // 2. Calcul du cap boussole réel de visée (Yaw) : angle dans le plan horizontal (0°=N, 90°=E)
            let yawRad = atan2(vy, vx)
            var yaw = yawRad * 180.0 / .pi
            if yaw < 0 { yaw += 360.0 }
            yaw = yaw.truncatingRemainder(dividingBy: 360.0)

            // 3. Roulis autour de l'axe de visée (pour compenser l'inclinaison de l'appareil)
            let roll = motion.attitude.roll * 180.0 / .pi

            self.pitchDegrees = pitch
            self.rollDegrees = roll
            self.yawDegrees = yaw
        }

        isTracking = true
    }

    func stopTracking() {
        guard isTracking else { return }
        motionManager.stopDeviceMotionUpdates()
        isTracking = false
    }
}
