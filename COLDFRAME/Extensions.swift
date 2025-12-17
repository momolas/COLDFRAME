//
//  PrayerTime.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import SwiftUI

// Thème "Gold & Dark"
extension Color {
    static let gold = Color(red: 0.83, green: 0.68, blue: 0.21)
    static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
}

// Structure de données pour les prières
struct PrayerTime: Identifiable {
    let id = UUID()
    let name: String
    let time: String
    let icon: String
}

// Structures pour le décodage API
struct PrayerResponse: Codable {
    let data: PrayerData
}
struct PrayerData: Codable {
    let timings: [String: String]
}