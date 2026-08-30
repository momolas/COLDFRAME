//
//  HilalVisibility.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import SwiftUI
import SwiftAA

nonisolated enum HilalVisibility: String, Equatable, Sendable {
    case notObservationDay = "not_observation_day"
    case impossible = "impossible"
    case obstructedByTerrain = "obstructed_by_terrain"
    case opticalAidOnly = "optical_aid_only"
    case opticalAidThenNakedEye = "optical_aid_then_naked_eye"
    case visibleNakedEyePerfectConditions = "visible_naked_eye_perfect_conditions"
    case easilyVisibleNakedEye = "easily_visible_naked_eye"

    init(zone: CrescentVisibilityZone) {
        switch zone {
        case .easilyVisibleNakedEye:
            self = .easilyVisibleNakedEye
        case .visibleNakedEyeUnderFavorableConditions:
            self = .visibleNakedEyePerfectConditions
        case .visibleOnlyWithOpticalAid:
            self = .opticalAidOnly
        case .notVisibleEvenWithOpticalAid, .belowDanjonLimit:
            self = .impossible
        }
    }

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

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .notObservationDay: return "hilal_not_observation_day"
        case .impossible: return "hilal_impossible"
        case .obstructedByTerrain: return "hilal_obstructed_terrain"
        case .opticalAidOnly: return "hilal_optical_aid_only"
        case .opticalAidThenNakedEye: return "hilal_optical_aid_then_naked"
        case .visibleNakedEyePerfectConditions: return "hilal_visible_perfect_conditions"
        case .easilyVisibleNakedEye: return "hilal_easily_visible_naked_eye"
        }
    }

    var localizedShortBadge: LocalizedStringKey {
        switch self {
        case .notObservationDay: return "hilal_badge_not_observation_day"
        case .impossible: return "hilal_badge_impossible"
        case .obstructedByTerrain: return "hilal_badge_obstructed_terrain"
        case .opticalAidOnly: return "hilal_badge_optical_aid_only"
        case .opticalAidThenNakedEye: return "hilal_badge_optical_aid_then_naked"
        case .visibleNakedEyePerfectConditions: return "hilal_badge_visible_perfect_conditions"
        case .easilyVisibleNakedEye: return "hilal_badge_easily_visible"
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
        return "\(degreesStr)° \(CardinalDirection.from(degrees: azimuthDegrees))"
    }

    var formattedMoonAltitude: String {
        let altStr = moonAltitudeDegrees.formatted(.number.precision(.fractionLength(1)))
        return "\(moonAltitudeDegrees >= 0 ? "+" : "")\(altStr)°"
    }

    var formattedBestObservationTime: String {
        guard let bestTime = bestObservationTime else { return "--:--" }
        return bestTime.formatted(date: .omitted, time: .shortened)
    }
}
