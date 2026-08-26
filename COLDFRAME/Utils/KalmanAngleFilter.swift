//
//  KalmanAngleFilter.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import Foundation

/// Filtre de Kalman 1D optimisé pour la fusion capteur Gyroscope + Accéléromètre / Boussole à 60 FPS
struct KalmanAngleFilter: Sendable {
    private var angle: Double = 0.0
    private var bias: Double = 0.0
    private var p00: Double = 1.0
    private var p01: Double = 0.0
    private var p10: Double = 0.0
    private var p11: Double = 1.0

    // Constantes de bruit calibrées pour les capteurs MEMS Apple
    private let qAngle: Double = 0.001
    private let qBias: Double = 0.003
    private let rMeasure: Double = 0.03

    private var isInitialized: Bool = false
    private let isCircular: Bool

    init(isCircular: Bool = false) {
        self.isCircular = isCircular
    }

    mutating func reset() {
        angle = 0.0
        bias = 0.0
        p00 = 1.0
        p01 = 0.0
        p10 = 0.0
        p11 = 1.0
        isInitialized = false
    }

    mutating func update(measuredAngle: Double, gyroRateDegreesPerSec: Double, dt: Double) -> Double {
        if !isInitialized {
            angle = measuredAngle
            isInitialized = true
            return angle
        }

        // 1. Étape de Prédiction (Intégration Gyroscope à haute fréquence)
        let rate = gyroRateDegreesPerSec - bias
        angle += rate * dt

        // Mise à jour de la matrice de covariance
        p00 += dt * (dt * p11 - p01 - p10 + qAngle)
        p01 -= dt * p11
        p10 -= dt * p11
        p11 += qBias * dt

        // 2. Différence angulaire minimale
        var diff: Double
        if isCircular {
            diff = (measuredAngle - angle).truncatingRemainder(dividingBy: 360.0)
            if diff > 180.0 { diff -= 360.0 }
            if diff < -180.0 { diff += 360.0 }
        } else {
            diff = measuredAngle - angle
        }

        // 3. Calcul du Gain de Kalman
        let s = p00 + rMeasure
        let k0 = p00 / s
        let k1 = p10 / s

        // 4. Étape de Correction (Pondération avec la mesure absolue)
        angle += k0 * diff
        bias += k1 * diff

        // Mise à jour de la matrice de covariance après mesure
        let p00Temp = p00
        let p01Temp = p01
        p00 -= k0 * p00Temp
        p01 -= k0 * p01Temp
        p10 -= k1 * p00Temp
        p11 -= k1 * p01Temp

        if isCircular {
            angle = (angle.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        }

        return angle
    }
}
