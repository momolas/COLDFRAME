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

    @ObservationIgnored private var lastCalculationDate: Date?
    @ObservationIgnored private var lastCalculationLocation: CLLocation?

    // Coordonnées de la Kaaba (La Mecque)
    let meccaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Optimize: 50 meters throttle to reduce re-renders
        locationManager.headingFilter = 1   // Optimize: 1 degree throttle to reduce battery usage
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
            self.liveMoonPosition = await AstronomicManager.getLiveMoonPosition(for: Date(), location: loc)
            obsData.isAnalyzingTerrain = true
            obsData.isFetchingWeather = true
            self.hilalObservation = obsData

            // Fetch météo crépusculaire en tâche asynchrone
            async let terrainTask = ElevationService.shared.fetchTerrainProfile(
                from: loc,
                azimuthDegrees: obsData.azimuthDegrees,
                moonAltitudeDegrees: obsData.moonAltitudeDegrees
            )
            async let weatherTask = WeatherService.shared.fetchObservationWeather(
                for: loc.coordinate,
                targetTime: obsData.bestObservationTime ?? maghrib ?? Date()
            )

            let (terrain, weather) = await (terrainTask, weatherTask)

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

    // MARK: - CoreLocation Delegate
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        MainActor.assumeIsolated {
            // Utiliser le Vrai Nord (True Heading) si disponible, sinon le Magnétique
            let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            self.heading = h
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
