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

            // Dans CoreMotion avec xTrueNorthZVertical (repère main droite) :
            // +X = Vrai Nord, +Y = Ouest (car Nord x Ouest = Haut), +Z = Haut (Zénith)
            // L'axe optique de la caméra arrière pointe vers (0, 0, -1) dans le repère appareil
            let northComp = -matrix.m13 // Composante Nord
            let eastComp = matrix.m23   // Composante Est (+m23 car +Y est Ouest)
            let upComp = -matrix.m33    // Composante Verticale (Zénith)

            // 1. Calcul de l'élévation optique réelle (Pitch) : angle avec le plan horizontal
            let clampedUp = max(-1.0, min(1.0, upComp))
            let pitch = asin(clampedUp) * 180.0 / .pi

            // 2. Calcul du cap boussole réel (Yaw) : 0°=Nord, 90°=Est, 180°=Sud, 270°=Ouest
            let yawRad = atan2(eastComp, northComp)
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
