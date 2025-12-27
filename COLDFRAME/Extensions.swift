//
//  Extensions.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//

import SwiftUI

// Thème de couleurs
extension Color {
	static let gold = Color(red: 0.83, green: 0.68, blue: 0.21)
	static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
}

// Modèle de données pour une prière
struct PrayerTime: Identifiable, Hashable {
	let id = UUID()
	let name: String
	let time: String // Format "HH:mm"
    let date: Date // Date réelle de la prière
	let icon: String // Nom SF Symbol
}

// Extensions mathématiques pour les conversions
extension Double {
	var deg2rad: Double { return self * .pi / 180 }
	var rad2deg: Double { return self * 180 / .pi }
}
