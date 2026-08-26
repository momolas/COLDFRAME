//
//  ElevationService.swift
//  COLDFRAME
//

import Foundation
import CoreLocation

/// Service responsable de la récupération du modèle numérique de terrain (MNT)
/// et du calcul de l'obstruction d'horizon le long de la ligne de visée.
actor ElevationService {
    static let shared = ElevationService()

    private let sampleDistancesKm: [Double] = [0.5, 1.0, 2.0, 3.5, 5.0, 7.5, 10.0, 15.0, 20.0, 25.0, 30.0]
    private let earthRadiusKm: Double = 6371.0
    // Rayon effectif avec réfraction atmosphérique standard (4/3 R)
    private let effectiveEarthRadiusMeters: Double = 8494667.0

    struct OpenMeteoElevationResponse: Decodable, Sendable {
        let elevation: [Double]
    }

    /// Récupère et calcule le profil altimétrique face à l'azimut donné
    func fetchTerrainProfile(
        from observerLocation: CLLocation,
        azimuthDegrees: Double,
        moonAltitudeDegrees: Double
    ) async -> TerrainProfile? {
        let observerCoord = observerLocation.coordinate
        
        // 1. Génération des coordonnées échantillonnées (du point 0 jusqu'à 30 km)
        var sampleCoordinates: [(distanceKm: Double, coord: CLLocationCoordinate2D)] = [
            (0.0, observerCoord)
        ]

        for distKm in sampleDistancesKm {
            let coord = destinationCoordinate(from: observerCoord, distanceKm: distKm, bearingDegrees: azimuthDegrees)
            sampleCoordinates.append((distKm, coord))
        }

        // 2. Préparation de la requête vers Open-Meteo Elevation API (avec locale POSIX pour forcer le point décimal)
        let posixLocale = Locale(identifier: "en_US_POSIX")
        let lats = sampleCoordinates.map {
            $0.coord.latitude.formatted(.number.locale(posixLocale).precision(.fractionLength(4)).grouping(.never))
        }.joined(separator: ",")
        let lons = sampleCoordinates.map {
            $0.coord.longitude.formatted(.number.locale(posixLocale).precision(.fractionLength(4)).grouping(.never))
        }.joined(separator: ",")

        guard let url = URL(string: "https://api.open-meteo.com/v1/elevation?latitude=\(lats)&longitude=\(lons)") else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let decoded = try JSONDecoder().decode(OpenMeteoElevationResponse.self, from: data)
            guard decoded.elevation.count == sampleCoordinates.count else {
                return nil
            }

            // 3. Altitude de l'observateur (utiliser l'altitude GPS si valide > -100m, sinon l'altitude MNT au sol)
            let observerGroundAlt = decoded.elevation[0]
            let observerAlt = observerLocation.altitude > -100 ? observerLocation.altitude : observerGroundAlt
            
            // Dépression d'horizon causée par l'altitude (en degrés)
            let horizonDip = 0.0293 * sqrt(max(0.0, observerAlt))

            // 4. Calcul de l'angle d'élévation pour chaque point avec courbure et réfraction
            var elevationPoints: [ElevationPoint] = []
            var maxAngle: Double = -90.0
            var maxAngleDist: Double = 0.0

            for i in 0..<sampleCoordinates.count {
                let distKm = sampleCoordinates[i].distanceKm
                let coord = sampleCoordinates[i].coord
                let elev = decoded.elevation[i]

                if distKm == 0.0 {
                    elevationPoints.append(
                        ElevationPoint(
                            distanceKm: 0.0,
                            latitude: coord.latitude,
                            longitude: coord.longitude,
                            elevationMeters: elev,
                            angleDegrees: 0.0
                        )
                    )
                    continue
                }

                let distMeters = distKm * 1000.0
                // Correction courbure + réfraction atmosphérique : d^2 / (2 * R_eff)
                let curvatureDrop = (distMeters * distMeters) / (2.0 * effectiveEarthRadiusMeters)
                let deltaHeightApparent = (elev - observerAlt) - curvatureDrop
                
                // Angle angulaire depuis l'observateur
                let angleRad = atan2(deltaHeightApparent, distMeters)
                let angleDeg = angleRad * 180.0 / .pi

                if angleDeg > maxAngle {
                    maxAngle = angleDeg
                    maxAngleDist = distKm
                }

                elevationPoints.append(
                    ElevationPoint(
                        distanceKm: distKm,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        elevationMeters: elev,
                        angleDegrees: angleDeg
                    )
                )
            }

            let finalMaxObstructionAngle = max(0.0, maxAngle)
            let isObstructed = finalMaxObstructionAngle >= moonAltitudeDegrees

            return TerrainProfile(
                observerAltitudeMeters: observerAlt,
                points: elevationPoints,
                maxObstructionAngle: finalMaxObstructionAngle,
                maxObstructionDistanceKm: maxAngleDist,
                isObstructed: isObstructed,
                moonAltitudeDegrees: moonAltitudeDegrees,
                horizonDipDegrees: horizonDip
            )
        } catch {
            return nil
        }
    }

    /// Calcule un point cible à partir d'une distance et d'un cap géodésique
    private func destinationCoordinate(
        from start: CLLocationCoordinate2D,
        distanceKm: Double,
        bearingDegrees: Double
    ) -> CLLocationCoordinate2D {
        let dRad = distanceKm / earthRadiusKm
        let bearingRad = bearingDegrees * .pi / 180.0

        let lat1 = start.latitude * .pi / 180.0
        let lon1 = start.longitude * .pi / 180.0

        let lat2 = asin(sin(lat1) * cos(dRad) + cos(lat1) * sin(dRad) * cos(bearingRad))
        let lon2 = lon1 + atan2(sin(bearingRad) * sin(dRad) * cos(lat1), cos(dRad) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(
            latitude: lat2 * 180.0 / .pi,
            longitude: lon2 * 180.0 / .pi
        )
    }
}
