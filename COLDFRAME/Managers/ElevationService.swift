//
//  ElevationService.swift
//  COLDFRAME
//

import Foundation
import CoreLocation

/// Protocole décrivant le service altimétrique et de profil MNT
protocol ElevationServiceProtocol: Sendable {
    func fetchTerrainProfile(
        from observerLocation: CLLocation,
        azimuthDegrees: Double,
        moonAltitudeDegrees: Double
    ) async -> TerrainProfile?

    func fetchPanoramicSkyline(from observerLocation: CLLocation) async -> (
        skyline: [SkylinePoint],
        foreground: [SkylinePoint],
        midground: [SkylinePoint],
        background: [SkylinePoint],
        peaks: [MountainPeak]
    )
}

/// Service hybride responsable de la récupération du modèle numérique de terrain (MNT) :
/// - Utilise le LiDAR HD National IGN (résolution 1m) pour la France
/// - Utilise le modèle mondial Copernicus DEM GLO-30 (résolution 30m) pour le reste du monde avec bascule automatique.
actor ElevationService: ElevationServiceProtocol {
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
            let z: Double?
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
            return decoded.elevations.map { pt in
                let val = pt.z ?? 0.0
                return val < -1000.0 ? 0.0 : max(0.0, val)
            }
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

    /// Récupère la ligne de crête panoramique (Skyline 360°) décomposée en 3 plans de profondeur et les sommets
    func fetchPanoramicSkyline(from observerLocation: CLLocation) async -> (
        skyline: [SkylinePoint],
        foreground: [SkylinePoint],
        midground: [SkylinePoint],
        background: [SkylinePoint],
        peaks: [MountainPeak]
    ) {
        let observerCoord = observerLocation.coordinate
        let observerAlt = observerLocation.altitude > -100 ? observerLocation.altitude : 0.0

        // Échantillonnage de 48 directions d'azimut (tous les 7.5° de 0° à 352.5°)
        // 4 strates de distance : 2.5 km (avant-plan), 7 km (moyen), 16 km et 30 km (lointain) -> 192 points
        var sampleCoordinates: [(azimuth: Double, distanceKm: Double, coord: CLLocationCoordinate2D)] = []
        let azimuths = stride(from: 0.0, to: 360.0, by: 7.5)
        let distances = [2.5, 7.0, 16.0, 30.0]

        for az in azimuths {
            for dist in distances {
                let coord = destinationCoordinate(from: observerCoord, distanceKm: dist, bearingDegrees: az)
                sampleCoordinates.append((azimuth: az, distanceKm: dist, coord: coord))
            }
        }

        // Récupération par lots de 50 points en parallèle
        guard let elevations = await fetchElevationsBatch(coordinates: sampleCoordinates.map(\.coord)),
              elevations.count == sampleCoordinates.count else {
            return ([], [], [], [], [])
        }

        var skylineMap: [Double: (maxAngle: Double, dist: Double, alt: Double)] = [:]
        var foregroundMap: [Double: (angle: Double, dist: Double, alt: Double)] = [:]
        var midgroundMap: [Double: (angle: Double, dist: Double, alt: Double)] = [:]
        var backgroundMap: [Double: (angle: Double, dist: Double, alt: Double)] = [:]

        for i in 0..<sampleCoordinates.count {
            let az = sampleCoordinates[i].azimuth
            let distKm = sampleCoordinates[i].distanceKm
            let elev = elevations[i]

            let distMeters = distKm * 1000.0
            let curvatureDrop = (distMeters * distMeters) / (2.0 * effectiveEarthRadiusMeters)
            let deltaHeightApparent = (elev - observerAlt) - curvatureDrop
            let angleDeg = atan2(deltaHeightApparent, distMeters) * 180.0 / .pi

            // 1. Classification par couche de distance
            if distKm <= 3.5 {
                foregroundMap[az] = (angle: max(0.0, angleDeg), dist: distKm, alt: elev)
            } else if distKm <= 10.0 {
                midgroundMap[az] = (angle: max(0.0, angleDeg), dist: distKm, alt: elev)
            } else {
                if let existingBg = backgroundMap[az] {
                    if angleDeg > existingBg.angle {
                        backgroundMap[az] = (angle: max(0.0, angleDeg), dist: distKm, alt: elev)
                    }
                } else {
                    backgroundMap[az] = (angle: max(0.0, angleDeg), dist: distKm, alt: elev)
                }
            }

            // 2. Ligne de crête globale maximale
            if let existing = skylineMap[az] {
                if angleDeg > existing.maxAngle {
                    skylineMap[az] = (maxAngle: angleDeg, dist: distKm, alt: elev)
                }
            } else {
                skylineMap[az] = (maxAngle: angleDeg, dist: distKm, alt: elev)
            }
        }

        let sortedSkyline = skylineMap.keys.sorted().compactMap { az -> SkylinePoint? in
            guard let data = skylineMap[az] else { return nil }
            return SkylinePoint(
                azimuthDegrees: az,
                elevationAngleDegrees: data.maxAngle,
                distanceKm: data.dist,
                altitudeMeters: data.alt
            )
        }

        let sortedForeground = foregroundMap.keys.sorted().compactMap { az -> SkylinePoint? in
            guard let data = foregroundMap[az] else { return nil }
            return SkylinePoint(
                azimuthDegrees: az,
                elevationAngleDegrees: data.angle,
                distanceKm: data.dist,
                altitudeMeters: data.alt
            )
        }

        let sortedMidground = midgroundMap.keys.sorted().compactMap { az -> SkylinePoint? in
            guard let data = midgroundMap[az] else { return nil }
            return SkylinePoint(
                azimuthDegrees: az,
                elevationAngleDegrees: data.angle,
                distanceKm: data.dist,
                altitudeMeters: data.alt
            )
        }

        let sortedBackground = backgroundMap.keys.sorted().compactMap { az -> SkylinePoint? in
            guard let data = backgroundMap[az] else { return nil }
            return SkylinePoint(
                azimuthDegrees: az,
                elevationAngleDegrees: data.angle,
                distanceKm: data.dist,
                altitudeMeters: data.alt
            )
        }

        var peaks: [MountainPeak] = []
        if sortedSkyline.count >= 3 {
            for i in 0..<sortedSkyline.count {
                let prev = sortedSkyline[(i - 1 + sortedSkyline.count) % sortedSkyline.count]
                let curr = sortedSkyline[i]
                let next = sortedSkyline[(i + 1) % sortedSkyline.count]

                if curr.elevationAngleDegrees > prev.elevationAngleDegrees &&
                   curr.elevationAngleDegrees > next.elevationAngleDegrees &&
                   curr.elevationAngleDegrees > 0.3 {
                    let azInt = Int64(curr.azimuthDegrees.rounded())
                    let altInt = Int64(curr.altitudeMeters.rounded())
                    let name = String(localized: "peak_ridge_format", defaultValue: "Crête \(azInt)° • \(altInt)m")
                    peaks.append(MountainPeak(
                        name: name,
                        azimuthDegrees: curr.azimuthDegrees,
                        elevationAngleDegrees: curr.elevationAngleDegrees,
                        distanceKm: curr.distanceKm,
                        altitudeMeters: curr.altitudeMeters
                    ))
                }
            }
        }

        return (sortedSkyline, sortedForeground, sortedMidground, sortedBackground, peaks)
    }

    /// Récupère des altitudes en découpant en requêtes batch de 50 coordonnées max (exécutées en parallèle)
    private func fetchElevationsBatch(coordinates: [CLLocationCoordinate2D]) async -> [Double]? {
        guard !coordinates.isEmpty else { return [] }
        let chunkSize = 50
        let posixLocale = Locale(identifier: "en_US_POSIX")

        var chunks: [(index: Int, chunk: [CLLocationCoordinate2D])] = []
        var chunkIndex = 0
        for startIdx in stride(from: 0, to: coordinates.count, by: chunkSize) {
            let endIdx = min(startIdx + chunkSize, coordinates.count)
            let chunk = Array(coordinates[startIdx..<endIdx])
            chunks.append((index: chunkIndex, chunk: chunk))
            chunkIndex += 1
        }

        let results = await withTaskGroup(of: (Int, [Double]?).self) { group -> [Int: [Double]] in
            for item in chunks {
                group.addTask {
                    let lats = item.chunk.map {
                        $0.latitude.formatted(.number.locale(posixLocale).precision(.fractionLength(4)).grouping(.never))
                    }.joined(separator: ",")
                    let lons = item.chunk.map {
                        $0.longitude.formatted(.number.locale(posixLocale).precision(.fractionLength(4)).grouping(.never))
                    }.joined(separator: ",")

                    guard let url = URL(string: "https://api.open-meteo.com/v1/elevation?latitude=\(lats)&longitude=\(lons)") else {
                        return (item.index, nil)
                    }

                    do {
                        var request = URLRequest(url: url)
                        request.timeoutInterval = 8.0
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                            return (item.index, nil)
                        }
                        let decoded = try JSONDecoder().decode(OpenMeteoElevationResponse.self, from: data)
                        guard decoded.elevation.count == item.chunk.count else { return (item.index, nil) }
                        return (item.index, decoded.elevation)
                    } catch {
                        return (item.index, nil)
                    }
                }
            }

            var map: [Int: [Double]] = [:]
            for await (idx, elevations) in group {
                if let elev = elevations {
                    map[idx] = elev
                }
            }
            return map
        }

        var allElevations: [Double] = []
        for item in chunks {
            guard let elev = results[item.index] else { return nil }
            allElevations.append(contentsOf: elev)
        }

        return allElevations
    }
}
