//
//  QiblaManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation
import CoreLocation
import Combine
import UIKit
import SwiftUI
import Observation

@MainActor
@Observable
class QiblaManager: NSObject, CLLocationManagerDelegate {
	private let locationManager = CLLocationManager()
	private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
	
	var heading: Double = 0.0
	var qiblaAngle: Double = 0.0
	var isAligned: Bool = false
	var userLocation: CLLocationCoordinate2D?
	var prayerTimes: [PrayerTime] = []
	
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
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		Task { @MainActor in
            // Si le "Vrai Nord" est disponible (valeur >= 0), on l'utilise.
            // Sinon, on se rabat sur le magnétique (moins précis pour la Qibla).
            let capUtilise = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading

            // On lisse un peu le mouvement pour éviter que l'aiguille ne tremble
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                self.heading = capUtilise
            }

            checkAlignment()
        }
	}
	
	nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.userLocation = location.coordinate
            self.qiblaAngle = calculateQiblaAngle(from: location)

            // Recalculer les horaires si la position change significativement ou si vide
            if prayerTimes.isEmpty {
                calculatePrayersLocally(for: location)
            }
        }
	}
	
	// MARK: - Qibla Calcul
	private func calculateQiblaAngle(from location: CLLocation) -> Double {
		let lat1 = location.coordinate.latitude.deg2rad
		let lon1 = location.coordinate.longitude.deg2rad
		
		let lat2 = 21.4225.deg2rad // Latitude Mecque
		let lon2 = 39.8262.deg2rad // Longitude Mecque
		
		let dLon = lon2 - lon1
		
		let y = sin(dLon)
		let x = cos(lat1) * tan(lat2) - sin(lat1) * cos(dLon)
		
		let angleRad = atan2(y, x)
		let angleDeg = angleRad.rad2deg
		
		// Normalisation pour avoir toujours un angle positif (0 à 360)
		return (angleDeg + 360).truncatingRemainder(dividingBy: 360)
	}
	
	private func checkAlignment() {
		let diff = abs(qiblaAngle - heading)
		if diff <= 2.0 || diff >= 358.0 {
			if !isAligned {
				isAligned = true
				feedbackGenerator.impactOccurred()
			}
		} else {
			isAligned = false
		}
	}
	
	// MARK: - Calcul des Horaires (Méthode Astronomique)
	func calculatePrayersLocally(for location: CLLocation) {
		let now = Date()
		let timeZone = Double(TimeZone.current.secondsFromGMT()) / 3600.0
		let jd = IslamicAstronomy.getJulianDay(date: now)
		let sunPos = IslamicAstronomy.calculateSunPosition(jd: jd)
		
		let lat = location.coordinate.latitude
		let lon = location.coordinate.longitude
		
		// 1. Midi Solaire (Dhuhr)
		// Formule: 12 + Zone - Long - EoT
		let midDay = 12.0 + timeZone - (lon / 15.0) - (sunPos.equationOfTime / 60.0)
		
		// 2. Angles de calcul (Convention standard : ISNA ou MWL)
		// Fajr: -18°, Isha: -17° ou -18°, Maghrib: -0.833° (réfraction)
		let fajrAltitude = -18.0
		let ishaAltitude = -17.0
		let sunriseSetAltitude = -0.833
		
		// 3. Calcul des durées (demi-arcs)
		guard let fajrT = IslamicAstronomy.calculateHourAngle(altitude: fajrAltitude, lat: lat, declination: sunPos.declination),
			  let sunT = IslamicAstronomy.calculateHourAngle(altitude: sunriseSetAltitude, lat: lat, declination: sunPos.declination),
			  let ishaT = IslamicAstronomy.calculateHourAngle(altitude: ishaAltitude, lat: lat, declination: sunPos.declination) else {
			return
		}
		
		// Pour Asr, on calcule d'abord l'altitude requise
		let asrAlt = IslamicAstronomy.calculateAsrAltitude(lat: lat, declination: sunPos.declination)
		guard let asrT = IslamicAstronomy.calculateHourAngle(altitude: asrAlt, lat: lat, declination: sunPos.declination) else { return }
		
		// 4. Détermination des heures finales
		let fajrTime = midDay - fajrT
		// let sunriseTime = midDay - sunT // (Optionnel)
		let dhuhrTime = midDay + (2.0/60.0) // On ajoute souvent 2 min de marge
		let asrTime = midDay + asrT
		let maghribTime = midDay + sunT
		let ishaTime = midDay + ishaT
		
		let times: [(String, Double, String)] = [
			("Fajr", fajrTime, "sun.haze.fill"),
			("Dhuhr", dhuhrTime, "sun.max.fill"),
			("Asr", asrTime, "sun.min.fill"),
			("Maghrib", maghribTime, "sunset.fill"),
			("Isha", ishaTime, "moon.stars.fill")
		]
		
		// 5. Formatage et Mise à jour
		let formattedTimes = times.map { (name, decimal, icon) in
			return PrayerTime(name: name, time: formatDecimalTime(decimal), icon: icon)
		}
		
        // Already on MainActor
        self.prayerTimes = formattedTimes
        NotificationManager.shared.cancelAllNotifications()
        for prayer in formattedTimes {
            NotificationManager.shared.scheduleNotification(for: prayer)
        }
	}
	
	private func formatDecimalTime(_ time: Double) -> String {
		var t = time
		if t >= 24 { t -= 24 }
		if t < 0 { t += 24 }
		
		let hours = Int(t)
		let minutes = Int((t - Double(hours)) * 60)
		return String(format: "%02d:%02d", hours, minutes)
	}
}
