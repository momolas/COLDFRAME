//
//  ElevationService.swift
//  COLDFRAME
//

import Foundation
import CoreLocation

/// Service hybride responsable de la récupération du modèle numérique de terrain (MNT) :
/// - Utilise le LiDAR HD National IGN (résolution 1m) pour la France
/// - Utilise le modèle mondial Copernicus DEM GLO-30 (résolution 30m) pour le reste du monde avec bascule automatique.
actor ElevationService {
    static let shared = ElevationService()

    private let sampleDistancesKm: [Double] = [0.5, 1.0, 2.0, 3.5, 5.0, 7.5, 10.0, 15.0, 20.0, 25.0, 30.0]
    private let earthRadiusKm: Double = 6371.0
    // Rayon effectif avec réfraction atmosphérique standard (4/3 R)
    private let effectiveEarthRadiusMeters: Double = 8494667.0

    private struct OpenMeteoElevationResponse: Decodable, Sendable {
        let elevation: [Double]
    }

    private struct IGNElevationResponse: Decodable, Sendable {
        struct Point: Decodable, Sendable {
            let z: Double
        }
        let elevations: [Point]
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

        // 2. Routage intelligent : Tenter le LiDAR HD IGN si en France, sinon Copernicus DEM
        var elevations: [Double]?
        var activeDataSource = "Copernicus DEM (30m)"

        if isInFrenchTerritory(observerCoord) {
            if let ignElevations = await fetchIGNLiDARProfile(sampleCoordinates: sampleCoordinates) {
                elevations = ignElevations
                activeDataSource = "IGN LiDAR HD (1m)"
            }
        }

        // Si hors France ou si l'IGN a échoué (fallback)
        if elevations == nil {
            if let openMeteoElevations = await fetchOpenMeteoProfile(sampleCoordinates: sampleCoordinates) {
                elevations = openMeteoElevations
                activeDataSource = "Copernicus DEM (30m)"
            }
        }

        guard let elevationValues = elevations, elevationValues.count == sampleCoordinates.count else {
            return nil
        }

        // 3. Altitude de l'observateur (utiliser l'altitude GPS si valide > -100m, sinon l'altitude MNT au sol)
        let observerGroundAlt = elevationValues[0]
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
            let elev = elevationValues[i]

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
            horizonDipDegrees: horizonDip,
            dataSource: activeDataSource
        )
    }

    // MARK: - API IGN Géoplateforme (LiDAR HD 1m)
    private func fetchIGNLiDARProfile(sampleCoordinates: [(distanceKm: Double, coord: CLLocationCoordinate2D)]) async -> [Double]? {
        let posixLocale = Locale(identifier: "en_US_POSIX")
        let lons = sampleCoordinates.map {
            $0.coord.longitude.formatted(.number.locale(posixLocale).precision(.fractionLength(5)).grouping(.never))
        }.joined(separator: "|")
        let lats = sampleCoordinates.map {
            $0.coord.latitude.formatted(.number.locale(posixLocale).precision(.fractionLength(5)).grouping(.never))
        }.joined(separator: "|")

        guard let url = URL(string: "https://data.geopf.fr/altimetrie/1.0/calcul/alti/rest/elevation.json?lon=\(lons)&lat=\(lats)&resource=ign_rge_alti_wld") else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 6.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let decoded = try JSONDecoder().decode(IGNElevationResponse.self, from: data)
            guard decoded.elevations.count == sampleCoordinates.count else { return nil }
            return decoded.elevations.map(\.z)
        } catch {
            return nil
        }
    }

    // MARK: - API Mondiale Open-Meteo (Copernicus DEM 30m)
    private func fetchOpenMeteoProfile(sampleCoordinates: [(distanceKm: Double, coord: CLLocationCoordinate2D)]) async -> [Double]? {
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
            request.timeoutInterval = 8.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let decoded = try JSONDecoder().decode(OpenMeteoElevationResponse.self, from: data)
            guard decoded.elevation.count == sampleCoordinates.count else { return nil }
            return decoded.elevation
        } catch {
            return nil
        }
    }

    // MARK: - Détection Géographique
    private func isInFrenchTerritory(_ coord: CLLocationCoordinate2D) -> Bool {
        // France Métropolitaine & Corse
        if coord.latitude >= 41.0 && coord.latitude <= 51.5 && coord.longitude >= -5.5 && coord.longitude <= 10.0 {
            return true
        }
        // La Réunion
        if coord.latitude >= -21.5 && coord.latitude <= -20.7 && coord.longitude >= 55.1 && coord.longitude <= 55.9 {
            return true
        }
        // Guadeloupe / Martinique
        if coord.latitude >= 14.3 && coord.latitude <= 16.6 && coord.longitude >= -61.9 && coord.longitude <= -60.7 {
            return true
        }
        // Mayotte
        if coord.latitude >= -13.1 && coord.latitude <= -12.5 && coord.longitude >= 45.0 && coord.longitude <= 45.4 {
            return true
        }
        // Guyane
        if coord.latitude >= 2.0 && coord.latitude <= 6.0 && coord.longitude >= -54.7 && coord.longitude <= -51.5 {
            return true
        }
        return false
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

    /// Récupère la ligne de crête panoramique (Skyline 360°) autour de l'observateur
    func fetchPanoramicSkyline(from observerLocation: CLLocation) async -> [SkylinePoint] {
        let observerCoord = observerLocation.coordinate
        let observerAlt = observerLocation.altitude > -100 ? observerLocation.altitude : 0.0

        // On échantillonne 60 directions d'azimut (tous les 6° de 0° à 354°)
        // Pour chaque azimut, on analyse 2 distances de crête (5 km et 18 km)
        var sampleCoordinates: [(azimuth: Double, distanceKm: Double, coord: CLLocationCoordinate2D)] = []
        let azimuths = stride(from: 0.0, to: 360.0, by: 6.0)
        let distances = [5.0, 18.0]

        for az in azimuths {
            for dist in distances {
                let coord = destinationCoordinate(from: observerCoord, distanceKm: dist, bearingDegrees: az)
                sampleCoordinates.append((azimuth: az, distanceKm: dist, coord: coord))
            }
        }

        let posixLocale = Locale(identifier: "en_US_POSIX")
        let lats = sampleCoordinates.map {
            $0.coord.latitude.formatted(.number.locale(posixLocale).precision(.fractionLength(4)).grouping(.never))
        }.joined(separator: ",")
        let lons = sampleCoordinates.map {
            $0.coord.longitude.formatted(.number.locale(posixLocale).precision(.fractionLength(4)).grouping(.never))
        }.joined(separator: ",")

        guard let url = URL(string: "https://api.open-meteo.com/v1/elevation?latitude=\(lats)&longitude=\(lons)") else {
            return []
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8.0
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return []
            }
            let decoded = try JSONDecoder().decode(OpenMeteoElevationResponse.self, from: data)
            guard decoded.elevation.count == sampleCoordinates.count else { return [] }

            var skylineMap: [Double: (maxAngle: Double, dist: Double, alt: Double)] = [:]

            for i in 0..<sampleCoordinates.count {
                let az = sampleCoordinates[i].azimuth
                let distKm = sampleCoordinates[i].distanceKm
                let elev = decoded.elevation[i]

                let distMeters = distKm * 1000.0
                let curvatureDrop = (distMeters * distMeters) / (2.0 * effectiveEarthRadiusMeters)
                let deltaHeightApparent = (elev - observerAlt) - curvatureDrop
                let angleDeg = atan2(deltaHeightApparent, distMeters) * 180.0 / .pi

                if let existing = skylineMap[az] {
                    if angleDeg > existing.maxAngle {
                        skylineMap[az] = (maxAngle: angleDeg, dist: distKm, alt: elev)
                    }
                } else {
                    skylineMap[az] = (maxAngle: angleDeg, dist: distKm, alt: elev)
                }
            }

            let sortedPoints = skylineMap.keys.sorted().compactMap { az -> SkylinePoint? in
                guard let data = skylineMap[az] else { return nil }
                return SkylinePoint(
                    azimuthDegrees: az,
                    elevationAngleDegrees: data.maxAngle,
                    distanceKm: data.dist,
                    altitudeMeters: data.alt
                )
            }

            return sortedPoints
        } catch {
            return []
        }
    }
}
