//
//  PrayerTime.swift
//  COLDFRAME
//

import Foundation

struct PrayerTime: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let time: String // Format "HH:mm"
    let date: Date // Date réelle de la prière
    let icon: String // Nom SF Symbol
}
