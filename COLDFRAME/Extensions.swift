//
//  Extensions.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//

import SwiftUI

// Modèle de données pour une prière
struct PrayerTime: Identifiable, Hashable {
	let id = UUID()
	let name: String
	let time: String // Format "HH:mm"
    let date: Date // Date réelle de la prière
	let icon: String // Nom SF Symbol
}

// Modèle de données pour la visibilité du Hilal
enum HilalVisibility: String, Equatable {
    case notObservationDay = "Pas de recherche aujourd'hui"
    case impossible = "Observation impossible (Lune trop jeune)"
    case difficult = "Difficile à l'œil nu (Télescope recommandé)"
    case visible = "Facilement visible (Si ciel dégagé)"

    var icon: String {
        switch self {
        case .notObservationDay: return "moon.fill"
        case .impossible: return "moon.haze.fill"
        case .difficult: return "moon.dust.fill"
        case .visible: return "moonphase.waxing.crescent"
        }
    }

    var color: Color {
        switch self {
        case .notObservationDay: return .secondary
        case .impossible: return .red
        case .difficult: return .orange
        case .visible: return .green
        }
    }
}

// Extensions mathématiques pour les conversions
extension Double {
	var deg2rad: Double { return self * .pi / 180 }
	var rad2deg: Double { return self * 180 / .pi }
}
