//
//  HilalVisibility.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import SwiftUI

nonisolated enum HilalVisibility: String, Equatable, Sendable {
    case notObservationDay = "Pas de recherche aujourd'hui"
    case impossible = "Observation impossible (Lune trop jeune / Sous l'horizon)"
    case obstructedByTerrain = "Observation masquée par le relief"
    case opticalAidOnly = "Aide optique requise (Télescope / Jumelles)"
    case opticalAidThenNakedEye = "Aide optique pour repérage puis œil nu"
    case visibleNakedEyePerfectConditions = "Visible à l'œil nu (Ciel parfait)"
    case easilyVisibleNakedEye = "Facilement visible à l'œil nu"

    var icon: String {
        switch self {
        case .notObservationDay: return "moon.fill"
        case .impossible: return "moon.haze.fill"
        case .obstructedByTerrain: return "mountain.2.fill"
        case .opticalAidOnly: return "telescope.fill"
        case .opticalAidThenNakedEye: return "binoculars.fill"
        case .visibleNakedEyePerfectConditions: return "eye.fill"
        case .easilyVisibleNakedEye: return "moonphase.waxing.crescent"
        }
    }

    var color: Color {
        switch self {
        case .notObservationDay: return .secondary
        case .impossible: return .red
        case .obstructedByTerrain: return .orange
        case .opticalAidOnly: return .red
        case .opticalAidThenNakedEye: return .orange
        case .visibleNakedEyePerfectConditions: return .green
        case .easilyVisibleNakedEye: return .green
        }
    }

    var shortBadgeText: String {
        switch self {
        case .notObservationDay: return "Hors créneau"
        case .impossible: return "Impossible"
        case .obstructedByTerrain: return "Relief masqué"
        case .opticalAidOnly: return "Optique seule"
        case .opticalAidThenNakedEye: return "Jumelles d'abord"
        case .visibleNakedEyePerfectConditions: return "Œil nu (Ciel pur)"
        case .easilyVisibleNakedEye: return "Œil nu facile"
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

    // Paramètres scientifiques Odeh (2004) & Yallop (1997)
    var odehVValue: Double = 0.0
    var odehZone: String = "D"
    var yallopQValue: Double = 0.0
    var yallopZone: String = "F"
    var arcOfVisionDegrees: Double = 0.0          // ARCV (différence d'altitude Lune - Soleil)
    var azimuthDifferenceDegrees: Double = 0.0    // DAZ (différence d'azimut Lune - Soleil)
    var crescentWidthArcminutes: Double = 0.0     // W (largeur du croissant en minutes d'arc)

    // Horaires & fenêtre optimale
    var moonLagMinutes: Double = 0.0               // Différence de coucher (Moonset - Sunset)
    var sunsetTime: Date? = nil
    var moonsetTime: Date? = nil
    var bestObservationTime: Date? = nil          // Sunset + 4/9 * MoonLag

    // Météo & Relief
    var weatherConditions: WeatherConditions? = nil
    var terrainProfile: TerrainProfile? = nil
    var isAnalyzingTerrain: Bool = false
    var isFetchingWeather: Bool = false

    var formattedAzimuth: String {
        let degreesStr = azimuthDegrees.formatted(.number.precision(.fractionLength(0)))
        return "\(degreesStr)° \(cardinalDirection(from: azimuthDegrees))"
    }

    var formattedMoonAltitude: String {
        let altStr = moonAltitudeDegrees.formatted(.number.precision(.fractionLength(1)))
        return "\(moonAltitudeDegrees >= 0 ? "+" : "")\(altStr)°"
    }

    var formattedMoonLag: String {
        if moonLagMinutes <= 0 {
            return "Lune couchée avant le Soleil"
        }
        let mins = Int(moonLagMinutes.rounded())
        return "+\(mins) min après le coucher"
    }

    var formattedBestObservationTime: String {
        guard let bestTime = bestObservationTime else { return "--:--" }
        return bestTime.formatted(date: .omitted, time: .shortened)
    }

    private func cardinalDirection(from degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
        let index = Int((normalized + 11.25) / 22.5) % 16
        return directions[index]
    }
}
