//
//  HilalVisibility.swift
//  COLDFRAME
//

import SwiftUI

nonisolated enum HilalVisibility: String, Equatable, Sendable {
    case notObservationDay = "Pas de recherche aujourd'hui"
    case impossible = "Observation impossible (Lune trop jeune)"
    case obstructedByTerrain = "Observation masquée par le relief"
    case difficult = "Difficile à l'œil nu (Télescope recommandé)"
    case visible = "Facilement visible (Si ciel dégagé)"

    var icon: String {
        switch self {
        case .notObservationDay: return "moon.fill"
        case .impossible: return "moon.haze.fill"
        case .obstructedByTerrain: return "mountain.2.fill"
        case .difficult: return "moon.dust.fill"
        case .visible: return "moonphase.waxing.crescent"
        }
    }

    var color: Color {
        switch self {
        case .notObservationDay: return .secondary
        case .impossible: return .red
        case .obstructedByTerrain: return .orange
        case .difficult: return .orange
        case .visible: return .green
        }
    }
}

nonisolated struct HilalObservationData: Equatable, Sendable {
    var visibility: HilalVisibility = .notObservationDay
    var azimuthDegrees: Double = 0.0
    var moonAltitudeDegrees: Double = 0.0
    var moonAgeHours: Double = 0.0
    var elongationDegrees: Double = 0.0
    var observerAltitudeMeters: Double = 0.0
    var terrainProfile: TerrainProfile? = nil
    var isAnalyzingTerrain: Bool = false

    var formattedAzimuth: String {
        let degreesStr = azimuthDegrees.formatted(.number.precision(.fractionLength(0)))
        return "\(degreesStr)° \(cardinalDirection(from: azimuthDegrees))"
    }

    var formattedMoonAltitude: String {
        let altStr = moonAltitudeDegrees.formatted(.number.precision(.fractionLength(1)))
        return "\(moonAltitudeDegrees >= 0 ? "+" : "")\(altStr)°"
    }

    private func cardinalDirection(from degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
        let index = Int((normalized + 11.25) / 22.5) % 16
        return directions[index]
    }
}
