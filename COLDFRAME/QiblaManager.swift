//
//  QiblaManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//

import Foundation
import CoreLocation
import Observation

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

    private var lastCalculationDate: Date?
    private var lastCalculationLocation: CLLocation?

    private var lastCalculationDate: Date?
    private var lastCalculationLocation: CLLocation?

    // Coordonnées de la Kaaba (La Mecque)
    let meccaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        NotificationManager.shared.requestAuthorization()
    }

    // MARK: - CoreLocation Delegate
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            // Utiliser le Vrai Nord (True Heading) si disponible, sinon le Magnétique
            let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            self.heading = h
            self.checkAlignment()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location.coordinate

            // 1. Calcul Qibla (Formule Mathématique Orthodromique)
            self.qiblaAngle = self.calculateBearingToMecca(from: location)

            // 2. Calcul Horaires via SwiftAA (appel au AstronomicManager)
            // On évite de recalculer trop souvent
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
                self.calculatePrayersLocally(for: location)
            }
        }
    }

    // MARK: - Calcul Qibla
    private func calculateBearingToMecca(from location: CLLocation) -> Double {
        let lat1 = location.coordinate.latitude.deg2rad
        let lon1 = location.coordinate.longitude.deg2rad

        let lat2 = meccaCoordinate.latitude.deg2rad
        let lon2 = meccaCoordinate.longitude.deg2rad

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let radiansBearing = atan2(y, x)

        // Conversion en degrés et normalisation (0 à 360)
        return (radiansBearing.rad2deg + 360).truncatingRemainder(dividingBy: 360)
    }

    // MARK: - Calcul Horaires (SwiftAA)
    func calculatePrayersLocally(for location: CLLocation) {
        // On délègue le travail astronomique complexe à notre Manager dédié
        let calculatedTimes = AstronomicManager.getSolarData(for: location)

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
        // Trouver la première prière dont la date est future
        if let next = prayerTimes.first(where: { $0.date > now }) {
            self.nextPrayer = next
        } else {
            // Si toutes sont passées, la prochaine est Fajr demain (non géré ici pour l'instant, ou on pourrait garder nil)
            self.nextPrayer = nil
        }
    }

    // MARK: - Logic
    private func checkAlignment() {
        let diff = abs(qiblaAngle - heading)
        // Tolérance de 2 degrés
        if diff <= 2.0 || diff >= 358.0 {
            if !isAligned {
                isAligned = true
            }
        } else {
            isAligned = false
        }
    }
}
