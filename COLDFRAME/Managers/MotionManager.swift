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
        CMMotionManager.availableAttitudeReferenceFrames().contains(.xTrueNorthZVertical)
    }

    @ObservationIgnored private var isInitialized: Bool = false
    private let smoothingFactor: Double = 0.28 // Lissage optimal (réactivité 60Hz sans jitter)

    func startTracking() {
        guard !isTracking else { return }
        guard motionManager.isDeviceMotionAvailable else { return }

        isInitialized = false
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz pour une fluidité AR cinéma

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
            let rawPitch = asin(clampedUp) * 180.0 / .pi

            // 2. Calcul du cap boussole réel (Yaw) : 0°=Nord, 90°=Est, 180°=Sud, 270°=Ouest
            let yawRad = atan2(eastComp, northComp)
            var rawYaw = yawRad * 180.0 / .pi
            if rawYaw < 0 { rawYaw += 360.0 }
            rawYaw = rawYaw.truncatingRemainder(dividingBy: 360.0)

            // 3. Roulis autour de l'axe de visée (pour l'horizon artificiel 2D en paysage)
            let rawRoll = motion.attitude.roll * 180.0 / .pi
            let rawScreenRoll = atan2(matrix.m31, matrix.m32) * 180.0 / .pi

            // 4. Filtrage passe-bas anti-tremblement (Low-Pass Filter / EMA)
            if !self.isInitialized {
                self.pitchDegrees = rawPitch
                self.yawDegrees = rawYaw
                self.rollDegrees = rawRoll
                self.screenRollDegrees = rawScreenRoll
                self.isInitialized = true
            } else {
                self.pitchDegrees += (rawPitch - self.pitchDegrees) * self.smoothingFactor
                self.rollDegrees += (rawRoll - self.rollDegrees) * self.smoothingFactor

                var diffScreenRoll = rawScreenRoll - self.screenRollDegrees
                while diffScreenRoll > 180.0 { diffScreenRoll -= 360.0 }
                while diffScreenRoll < -180.0 { diffScreenRoll += 360.0 }
                self.screenRollDegrees += diffScreenRoll * self.smoothingFactor

                var diffYaw = rawYaw - self.yawDegrees
                while diffYaw > 180.0 { diffYaw -= 360.0 }
                while diffYaw < -180.0 { diffYaw += 360.0 }
                var smoothedYaw = self.yawDegrees + diffYaw * self.smoothingFactor
                if smoothedYaw < 0 { smoothedYaw += 360.0 }
                self.yawDegrees = smoothedYaw.truncatingRemainder(dividingBy: 360.0)
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
