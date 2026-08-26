//
//  HilalVisibility.swift
//  COLDFRAME
//

import SwiftUI

enum HilalVisibility: String, Equatable, Sendable {
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
