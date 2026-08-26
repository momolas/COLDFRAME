//
//  LiveMoonPosition.swift
//  COLDFRAME
//

import Foundation

/// Point sur la trajectoire céleste de la Lune
nonisolated struct MoonTrajectoryPoint: Identifiable, Sendable, Equatable {
    let id: UUID
    let date: Date
    let azimuthDegrees: Double
    let altitudeDegrees: Double
    let formattedTime: String

    init(
        id: UUID = UUID(),
        date: Date,
        azimuthDegrees: Double,
        altitudeDegrees: Double,
        formattedTime: String
    ) {
        self.id = id
        self.date = date
        self.azimuthDegrees = azimuthDegrees
        self.altitudeDegrees = altitudeDegrees
        self.formattedTime = formattedTime
    }
}

/// Point d'horizon pour la ligne de crête panoramique MNT (Skyline)
nonisolated struct SkylinePoint: Identifiable, Sendable, Equatable {
    let id: UUID
    let azimuthDegrees: Double
    let elevationAngleDegrees: Double
    let distanceKm: Double
    let altitudeMeters: Double

    init(
        id: UUID = UUID(),
        azimuthDegrees: Double,
        elevationAngleDegrees: Double,
        distanceKm: Double,
        altitudeMeters: Double
    ) {
        self.id = id
        self.azimuthDegrees = azimuthDegrees
        self.elevationAngleDegrees = elevationAngleDegrees
        self.distanceKm = distanceKm
        self.altitudeMeters = altitudeMeters
    }
}

/// Sommet ou crête remarquable identifié dans le panorama façon PeakFinder
nonisolated struct MountainPeak: Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let azimuthDegrees: Double
    let elevationAngleDegrees: Double
    let distanceKm: Double
    let altitudeMeters: Double

    init(
        id: UUID = UUID(),
        name: String,
        azimuthDegrees: Double,
        elevationAngleDegrees: Double,
        distanceKm: Double,
        altitudeMeters: Double
    ) {
        self.id = id
        self.name = name
        self.azimuthDegrees = azimuthDegrees
        self.elevationAngleDegrees = elevationAngleDegrees
        self.distanceKm = distanceKm
        self.altitudeMeters = altitudeMeters
    }
}

/// Position instantanée en direct de la Lune et du Soleil pour le repérage diurne et la RA
nonisolated struct LiveMoonPosition: Sendable, Equatable {
    var azimuthDegrees: Double = 0.0
    var altitudeDegrees: Double = 0.0
    var sunAzimuthDegrees: Double = 0.0
    var sunAltitudeDegrees: Double = 0.0
    var elongationDegrees: Double = 0.0
    var illuminatedFraction: Double = 0.0
    var trajectory: [MoonTrajectoryPoint] = []
    var skyline: [SkylinePoint] = []
    var peaks: [MountainPeak] = []

    var isAboveHorizon: Bool {
        altitudeDegrees > 0.0
    }

    var formattedAzimuth: String {
        let deg = azimuthDegrees.formatted(.number.precision(.fractionLength(0)))
        return "\(deg)° \(cardinalDirection(from: azimuthDegrees))"
    }

    var formattedAltitude: String {
        let altStr = altitudeDegrees.formatted(.number.precision(.fractionLength(1)))
        return "\(altitudeDegrees >= 0 ? "+" : "")\(altStr)°"
    }

    /// Guide de position par rapport au Soleil (pour repérer la Lune en plein jour sans regarder directement le Soleil)
    var relativeSunPositionText: String {
        guard sunAltitudeDegrees > -6.0 else {
            return "Visible de nuit dans le ciel"
        }

        let diffAz = (azimuthDegrees - sunAzimuthDegrees).truncatingRemainder(dividingBy: 360)
        let normalizedDiff = diffAz < -180 ? diffAz + 360 : (diffAz > 180 ? diffAz - 360 : diffAz)
        let angleAbs = abs(normalizedDiff).formatted(.number.precision(.fractionLength(0)))

        if abs(normalizedDiff) < 15 {
            return "Très proche du Soleil (Prudence, ne pas fixer le Soleil !)"
        } else if normalizedDiff > 0 {
            return "À ~\(angleAbs)° à gauche (Est) du Soleil"
        } else {
            return "À ~\(angleAbs)° à droite (Ouest) du Soleil"
        }
    }

    /// Guide d'élévation pratique (en doigts / mains tendues au-dessus de l'horizon)
    var elevationHandGuideText: String {
        if altitudeDegrees <= 0 {
            return "Actuellement sous l'horizon"
        } else if altitudeDegrees < 10 {
            return "Au ras de l'horizon (~1 poing)"
        } else if altitudeDegrees < 25 {
            let hands = Int(round(altitudeDegrees / 10.0))
            return "À mi-hauteur (~\(hands) poings au-dessus de l'horizon)"
        } else if altitudeDegrees < 60 {
            let hands = Int(round(altitudeDegrees / 10.0))
            return "Haut dans le ciel (~\(hands) poings fermés)"
        } else {
            return "Proche du Zénith (Regardez au-dessus de vous)"
        }
    }

    private func cardinalDirection(from degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
        let index = Int((normalized + 11.25) / 22.5) % 16
        return directions[index]
    }
}
