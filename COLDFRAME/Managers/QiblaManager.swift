//
//  QiblaManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//

import Foundation
import CoreLocation
import Observation
import SwiftAA

@MainActor
@Observable
class QiblaManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    var heading: Double = 0.0
    var trueHeading: Double = 0.0
    var magneticHeading: Double = 0.0
    var isTrueNorth: Bool = false // Nord Magnétique par défaut pour correspondance 1:1 avec la Boussole Apple
    var compassOffsetDegrees: Double = 0.0 // Décalage de calibrage manuel personnalisé
    var headingAccuracy: Double = -1.0
    var qiblaAngle: Double = 0.0
    var isAligned: Bool = false
    var userLocation: CLLocationCoordinate2D?
    var prayerTimes: [PrayerTime] = []
    var nextPrayer: PrayerTime? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var islamicDate: String = ""
    var moonPhaseName: String = ""
    var moonPhaseIcon: String = ""
    var moonIllumination: Double = 0.0
    var hilalObservation: HilalObservationData = HilalObservationData()
    var hilalVisibility: HilalVisibility {
        hilalObservation.visibility
    }
    var liveMoonPosition: LiveMoonPosition = LiveMoonPosition()

    // Options de terrain et observation AR
    var isNightVisionMode: Bool = false
    var showOpticalReticle: Bool = true
    var showTerrainSkyline: Bool = true

    @ObservationIgnored private var lastCalculationDate: Date?
    @ObservationIgnored private var lastCalculationLocation: CLLocation?

    // Coordonnées de la Kaaba (La Mecque)
    let meccaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Optimize: 50 meters throttle to reduce re-renders
        locationManager.headingFilter = kCLHeadingFilterNone // Précision maximale continue
        locationManager.headingOrientation = .portrait       // Repère fixe et stable (sommet de l'iPhone)
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        NotificationManager.shared.requestAuthorization()
        
        if let initialLoc = locationManager.location {
            self.userLocation = initialLoc.coordinate
            self.lastCalculationLocation = initialLoc
            Task {
                await self.calculatePrayersLocally(for: initialLoc)
                await self.updateIslamicDate(location: initialLoc)
            }
        } else {
            Task {
                await self.updateIslamicDate()
            }
        }

        self.startPeriodicUpdates()
    }

    isolated deinit {
        periodicTask?.cancel()
    }

    func toggleNorthReference() {
        isTrueNorth.toggle()
        let chosen = (isTrueNorth && trueHeading >= 0) ? trueHeading : magneticHeading
        let finalHeading = (chosen + self.compassOffsetDegrees).truncatingRemainder(dividingBy: 360.0)
        self.heading = (finalHeading + 360.0).truncatingRemainder(dividingBy: 360.0)
        self.checkAlignment()
    }

    private var periodicTask: Task<Void, Never>?

    private func startPeriodicUpdates() {
        periodicTask?.cancel()
        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard let self = self else { break }
                self.updateNextPrayer()

                // Si la date a changé (passage de minuit), recalculer les horaires
                if let loc = self.lastCalculationLocation,
                   let lastDate = self.lastCalculationDate,
                   !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
                    await self.calculatePrayersLocally(for: loc)
                    await self.updateIslamicDate(location: loc)
                } else if let loc = self.lastCalculationLocation {
                    // Mettre à jour la position instantanée de la Lune
                    let liveMoon = await AstronomicManager.getLiveMoonPosition(for: Date(), location: loc)
                    var currentLive = self.liveMoonPosition
                    currentLive.azimuthDegrees = liveMoon.azimuthDegrees
                    currentLive.altitudeDegrees = liveMoon.altitudeDegrees
                    currentLive.sunAzimuthDegrees = liveMoon.sunAzimuthDegrees
                    currentLive.sunAltitudeDegrees = liveMoon.sunAltitudeDegrees
                    currentLive.elongationDegrees = liveMoon.elongationDegrees
                    currentLive.illuminatedFraction = liveMoon.illuminatedFraction
                    self.liveMoonPosition = currentLive
                }
            }
        }
    }

    // MARK: - Calendrier Islamique & Hilal
    private func updateIslamicDate(location: CLLocation? = nil) async {
        var format = Date.FormatStyle.dateTime
            .day()
            .month(.wide)
            .year()
            .locale(Locale(identifier: "fr_FR"))
        format.calendar = Calendar(identifier: .islamicUmmAlQura)
        self.islamicDate = Date().formatted(format)

        let moonData = await AstronomicManager.getMoonPhase()
        self.moonPhaseName = moonData.name
        self.moonPhaseIcon = moonData.icon
        self.moonIllumination = moonData.illuminatedFraction

        let activeLocation = location ?? self.lastCalculationLocation
        let maghrib = self.prayerTimes.first { $0.name == "Maghrib" }?.date
        var obsData = await AstronomicManager.getHilalObservation(for: Date(), maghribDate: maghrib, location: activeLocation)

        if let loc = activeLocation {
            var liveMoon = await AstronomicManager.getLiveMoonPosition(for: Date(), location: loc)
            obsData.isAnalyzingTerrain = true
            obsData.isFetchingWeather = true
            self.hilalObservation = obsData

            let targetAz = obsData.azimuthDegrees
            let targetMoonAlt = obsData.moonAltitudeDegrees
            let targetObsTime = obsData.bestObservationTime ?? maghrib ?? Date()

            // Fetch météo, profil d'obstruction et crêtes 360° en parallèle
            async let terrainTask = ElevationService.shared.fetchTerrainProfile(
                from: loc,
                azimuthDegrees: targetAz,
                moonAltitudeDegrees: targetMoonAlt
            )
            async let weatherTask = WeatherService.shared.fetchObservationWeather(
                for: loc.coordinate,
                targetTime: targetObsTime
            )
            async let skylineTask = ElevationService.shared.fetchPanoramicSkyline(from: loc)

            let (terrain, weather, skylineResult) = await (terrainTask, weatherTask, skylineTask)

            liveMoon.skyline = skylineResult.skyline
            liveMoon.foregroundSkyline = skylineResult.foreground
            liveMoon.midgroundSkyline = skylineResult.midground
            liveMoon.backgroundSkyline = skylineResult.background
            liveMoon.peaks = skylineResult.peaks
            self.liveMoonPosition = liveMoon

            obsData.weatherConditions = weather
            obsData.isFetchingWeather = false

            if let terrain = terrain {
                obsData.terrainProfile = terrain
                if terrain.isObstructed {
                    obsData.visibility = .obstructedByTerrain
                }
            }
            obsData.isAnalyzingTerrain = false
        }

        self.hilalObservation = obsData
    }

    func refreshSkylineIfNeeded() {
        guard let loc = lastCalculationLocation ?? locationManager.location else { return }
        if self.liveMoonPosition.skyline.isEmpty {
            Task {
                let skylineResult = await ElevationService.shared.fetchPanoramicSkyline(from: loc)
                self.liveMoonPosition.skyline = skylineResult.skyline
                self.liveMoonPosition.foregroundSkyline = skylineResult.foreground
                self.liveMoonPosition.midgroundSkyline = skylineResult.midground
                self.liveMoonPosition.backgroundSkyline = skylineResult.background
                self.liveMoonPosition.peaks = skylineResult.peaks
            }
        }
    }

    // MARK: - CoreLocation Delegate
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
            }
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Autoriser iOS à afficher la modale d'étalonnage en 8 si le capteur est perturbé
        return true
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        MainActor.assumeIsolated {
            self.headingAccuracy = newHeading.headingAccuracy
            
            let rawMag = newHeading.magneticHeading
            guard rawMag >= 0 else { return }

            self.magneticHeading = (rawMag.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
            if newHeading.trueHeading >= 0 {
                self.trueHeading = (newHeading.trueHeading.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
            }

            let chosen = (self.isTrueNorth && newHeading.trueHeading >= 0) ? self.trueHeading : self.magneticHeading
            let finalHeading = (chosen + self.compassOffsetDegrees).truncatingRemainder(dividingBy: 360.0)
            self.heading = (finalHeading + 360.0).truncatingRemainder(dividingBy: 360.0)
            self.checkAlignment()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        MainActor.assumeIsolated {
            self.userLocation = location.coordinate

            // 1. Calcul Qibla (Formule Mathématique Orthodromique)
            self.qiblaAngle = self.calculateBearingToMecca(from: location)

            // 2. Calcul Horaires via SwiftAA (appel au AstronomicManager)
            let shouldUpdate: Bool = {
                if self.prayerTimes.isEmpty { return true }

                // Vérifier changement de jour
                if let lastDate = self.lastCalculationDate,
                   !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
                    return true
                }

                // Vérifier changement de position significatif (> 5km)
                if let lastLoc = self.lastCalculationLocation,
                   lastLoc.distance(from: location) > 5000 {
                    return true
                }

                return false
            }()

            if shouldUpdate {
                Task {
                    await self.calculatePrayersLocally(for: location)
                    await self.updateIslamicDate(location: location)
                }
            }
        }
    }

    // MARK: - Calcul Qibla
    private func calculateBearingToMecca(from location: CLLocation) -> Double {
        let lat1 = location.coordinate.latitude * deg2rad
        let lon1 = location.coordinate.longitude * deg2rad

        let lat2 = meccaCoordinate.latitude * deg2rad
        let lon2 = meccaCoordinate.longitude * deg2rad

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let radiansBearing = atan2(y, x)

        // Conversion en degrés et normalisation (0 à 360)
        return (radiansBearing * rad2deg + 360).truncatingRemainder(dividingBy: 360)
    }

    // MARK: - Calcul Horaires (SwiftAA)
    func calculatePrayersLocally(for location: CLLocation) async {
        let calculatedTimes = await AstronomicManager.getSolarData(for: location)

        self.prayerTimes = calculatedTimes
        self.updateNextPrayer()

        self.lastCalculationDate = Date()
        self.lastCalculationLocation = location

        // Notifications
        NotificationManager.shared.cancelAllNotifications()
        for prayer in calculatedTimes {
            NotificationManager.shared.scheduleNotification(for: prayer)
        }
    }

    private func updateNextPrayer() {
        let now = Date()
        if let next = prayerTimes.first(where: { $0.date > now }) {
            self.nextPrayer = next
        } else {
            self.nextPrayer = nil
        }
    }

    // MARK: - Logic
    private func checkAlignment() {
        let diff = abs(qiblaAngle - heading)
        // Tolérance de 2 degrés
        let aligned = diff <= 2.0 || diff >= 358.0
        if isAligned != aligned {
            isAligned = aligned
        }
    }
}
