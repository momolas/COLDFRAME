//
//  WeatherConditions.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import Foundation

nonisolated struct WeatherConditions: Equatable, Sendable {
    var cloudCoverTotalPercent: Int = 0
    var cloudCoverLowPercent: Int = 0
    var cloudCoverMidPercent: Int = 0
    var cloudCoverHighPercent: Int = 0
    var visibilityMeters: Double = 10000.0
    var relativeHumidityPercent: Int = 50
    var temperatureCelsius: Double = 20.0
    var observationTargetTime: Date? = nil

    /// Score de clarté céleste pour l'observation (0 à 100%)
    /// Pondération : 60% couverture nuageuse totale/basse, 25% visibilité horizontale, 15% humidité
    var seeingScore: Int {
        // Pénalité majeure si nuages bas/totaux
        let cloudPenalty = Double(max(cloudCoverTotalPercent, cloudCoverLowPercent)) * 0.7 + Double(cloudCoverMidPercent) * 0.2 + Double(cloudCoverHighPercent) * 0.1
        let cloudScore = max(0.0, 100.0 - cloudPenalty)

        // Score de visibilité (10 km = 100%, 1 km = 20%)
        let visibilityKm = visibilityMeters / 1000.0
        let visibilityScore = min(100.0, max(0.0, visibilityKm * 10.0))

        // Score d'humidité (une humidité > 85% favorise la brume crépusculaire)
        let humidityScore = relativeHumidityPercent > 80 ? max(0.0, 100.0 - Double(relativeHumidityPercent - 80) * 4.0) : 100.0

        let total = (cloudScore * 0.60) + (visibilityScore * 0.25) + (humidityScore * 0.15)
        return Int(total.rounded())
    }

    var seeingDescription: String {
        switch seeingScore {
        case 85...100:
            return "Ciel clair & limpide"
        case 65..<85:
            return "Voiles légers à l'horizon"
        case 40..<65:
            return "Partiellement nuageux"
        default:
            return "Ciel couvert / Bouché"
        }
    }

    var seeingIcon: String {
        switch seeingScore {
        case 85...100:
            return "sparkles"
        case 65..<85:
            return "sun.haze.fill"
        case 40..<65:
            return "cloud.sun.fill"
        default:
            return "cloud.fill"
        }
    }
}
