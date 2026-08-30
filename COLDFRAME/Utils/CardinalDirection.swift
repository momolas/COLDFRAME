//
//  CardinalDirection.swift
//  COLDFRAME
//
//  Created by Mo on 30/08/2026.
//

import Foundation

/// Utilitaire de calcul et de localisation uniforme des points cardinaux
enum CardinalDirection {
    private static let fullKeys: [String] = [
        "cardinal_n", "cardinal_nne", "cardinal_ne", "cardinal_ene",
        "cardinal_e", "cardinal_ese", "cardinal_se", "cardinal_sse",
        "cardinal_s", "cardinal_ssw", "cardinal_sw", "cardinal_wsw",
        "cardinal_w", "cardinal_wnw", "cardinal_nw", "cardinal_nnw"
    ]

    /// Retourne le nom localisé de la direction (ex: "N", "NNE", "NE", "SSO", "SO", etc.)
    static func from(degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let index = Int((normalized + 11.25) / 22.5) % 16
        return String(localized: String.LocalizationValue(fullKeys[index]))
    }

    /// Retourne la lettre cardinale pour les repères principaux (0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°)
    static func cardinalLetter(for angle: Double) -> String {
        let normalized = (angle.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        switch Int(normalized.rounded()) {
        case 0, 360: return String(localized: "cardinal_n")
        case 45: return String(localized: "cardinal_ne")
        case 90: return String(localized: "cardinal_e")
        case 135: return String(localized: "cardinal_se")
        case 180: return String(localized: "cardinal_s")
        case 225: return String(localized: "cardinal_sw")
        case 270: return String(localized: "cardinal_w")
        case 315: return String(localized: "cardinal_nw")
        default: return ""
        }
    }
}
