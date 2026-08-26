//
//  TerrainProfile.swift
//  COLDFRAME
//

import Foundation
import CoreLocation

/// Représente un point d'échantillonnage altimétrique le long de la ligne de visée
struct ElevationPoint: Identifiable, Sendable, Equatable {
    let id: UUID
    let distanceKm: Double
    let latitude: Double
    let longitude: Double
    let elevationMeters: Double
    let angleDegrees: Double

    init(
        id: UUID = UUID(),
        distanceKm: Double,
        latitude: Double,
        longitude: Double,
        elevationMeters: Double,
        angleDegrees: Double
    ) {
        self.id = id
        self.distanceKm = distanceKm
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.angleDegrees = angleDegrees
    }
}

/// Profil altimétrique complet dans la direction d'observation
struct TerrainProfile: Sendable, Equatable {
    let observerAltitudeMeters: Double
    let points: [ElevationPoint]
    let maxObstructionAngle: Double
    let maxObstructionDistanceKm: Double
    let isObstructed: Bool
    let moonAltitudeDegrees: Double
    let horizonDipDegrees: Double

    var summaryText: String {
        if isObstructed {
            let angleFormatted = maxObstructionAngle.formatted(.number.precision(.fractionLength(1)))
            let distFormatted = maxObstructionDistanceKm.formatted(.number.precision(.fractionLength(1)))
            return "Relief obstruant (+\(angleFormatted)° à \(distFormatted) km)"
        } else if maxObstructionAngle > 0 {
            let margin = (moonAltitudeDegrees - maxObstructionAngle).formatted(.number.precision(.fractionLength(1)))
            return "Horizon dégagé (marge de +\(margin)° au-dessus des crêtes)"
        } else {
            return "Horizon parfaitement dégagé"
        }
    }
}
